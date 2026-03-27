import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/registration_package.dart';
import '../services/bluetooth_printer_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _wifiPasswordController = TextEditingController();
  final _monthlyPriceController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  List<Printer> _devices = [];
  Printer? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initPrinter();
  }

  Future<void> _loadSettings() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.loadSettings();

    setState(() {
      _wifiPasswordController.text = settings.wifiPassword;
      _monthlyPriceController.text = settings.monthlyPrice.toString();
      _headerController.text = settings.receiptHeader;
      _footerController.text = settings.receiptFooter;
    });
  }

  Future<void> _initPrinter() async {
    final printer = BluetoothPrinterService.instance;
    final permissionsGranted = await printer.requestPermissions();

    if (permissionsGranted) {
      if (await printer.isConnected()) {
        setState(() {
          _selectedDevice = printer.selectedPrinter;
          _isConnected = true;
        });
      }
      _scanDevices();
    }
  }

  Future<void> _scanDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await BluetoothPrinterService.instance.getDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleConnection(Printer device) async {
    final printer = BluetoothPrinterService.instance;

    setState(() => _isLoading = true);

    try {
      if (_isConnected && _selectedDevice?.address == device.address) {
        await printer.disconnect();
        setState(() {
          _isConnected = false;
          _selectedDevice = null;
        });
      } else {
        if (_isConnected) {
          await printer.disconnect();
        }
        final connected = await printer.connect(device);
        setState(() {
          _isConnected = connected;
          if (connected) _selectedDevice = device;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    await settings.updateSetting('wifi_password', _wifiPasswordController.text);
    await settings.updateSetting('monthly_price', _monthlyPriceController.text);
    await settings.updateSetting('receipt_header', _headerController.text);
    await settings.updateSetting('receipt_footer', _footerController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAddPackageModal(BuildContext context,
      {RegistrationPackage? package}) {
    final isEdit = package != null;
    final nameController =
        TextEditingController(text: isEdit ? package.name : '');
    final priceController =
        TextEditingController(text: isEdit ? package.price.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit Paket' : 'Tambah Paket Baru',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: nameController,
                  label: 'Nama Paket',
                  icon: Icons.local_offer_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: priceController,
                  label: 'Harga',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty) return;

                    final settings =
                        Provider.of<SettingsProvider>(context, listen: false);
                    final newPkg = RegistrationPackage(
                      id: package?.id,
                      name: nameController.text,
                      price: int.parse(priceController.text),
                    );

                    if (isEdit) {
                      await settings.updatePackage(newPkg);
                    } else {
                      await settings.addPackage(newPkg);
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Packages Section
            _buildSectionHeader('Manajemen Paket & Harga'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Column(
                children: [
                  if (settingsProvider.packages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Belum ada paket.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: settingsProvider.packages.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF2C2C2C), height: 1),
                      itemBuilder: (context, index) {
                        final pkg = settingsProvider.packages[index];
                        return ListTile(
                          title: Text(pkg.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text('Rp ${pkg.price}',
                              style: const TextStyle(color: Color(0xFF4FC3F7))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: Colors.grey, size: 20),
                                onPressed: () =>
                                    _showAddPackageModal(context, package: pkg),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  if (pkg.id != null) {
                                    await settingsProvider
                                        .deletePackage(pkg.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddPackageModal(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Paket Baru'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Printer Settings
            _buildSectionHeader('Printer Thermal Bluetooth'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Perangkat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      if (_isLoading)
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: Color(0xFF4FC3F7)),
                          onPressed: _scanDevices,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_devices.isEmpty && !_isLoading)
                    const Text('Tidak ada perangkat ditemukan',
                        style: TextStyle(color: Colors.grey))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isSelected =
                            _selectedDevice?.address == device.address;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.print_rounded,
                            color: isSelected && _isConnected
                                ? const Color(0xFF4FC3F7)
                                : Colors.grey,
                          ),
                          title: Text(device.name ?? 'Unknown Device',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(device.address ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected && _isConnected
                                  ? Colors.redAccent
                                  : const Color(0xFF4FC3F7),
                              foregroundColor: isSelected && _isConnected
                                  ? Colors.white
                                  : Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () => _toggleConnection(device),
                            child: Text(
                                isSelected && _isConnected
                                    ? 'Putus'
                                    : 'Hubungkan',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Struk & Aplikasi
            _buildSectionHeader('Pengaturan Struk & Aplikasi'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _headerController,
                    label: 'Judul Struk (Header)',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _footerController,
                    label: 'Pesan Penutup Struk (Footer)',
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _wifiPasswordController,
                    label: 'Password WiFi Member',
                    icon: Icons.wifi_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Simpan Konfigurasi'),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF81D4FA),
        letterSpacing: 0.5,
      ),
    );
  }
}
