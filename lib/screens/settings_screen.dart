import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
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
  final _dailyPriceController = TextEditingController();
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
    _checkPrinterConnection();
  }

  @override
  void dispose() {
    _wifiPasswordController.dispose();
    _dailyPriceController.dispose();
    _monthlyPriceController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _wifiPasswordController.text = settings.wifiPassword;
    _dailyPriceController.text = settings.dailyPrice.toString();
    _monthlyPriceController.text = settings.monthlyPrice.toString();
    _headerController.text = settings.receiptHeader;
    _footerController.text = settings.receiptFooter;
  }

  Future<void> _checkPrinterConnection() async {
    final printer = BluetoothPrinterService.instance;
    final connected = await printer.isConnected();
    setState(() => _isConnected = connected);
  }

  Future<void> _scanDevices() async {
    final printer = BluetoothPrinterService.instance;
    
    // Request permissions
    final hasPermission = await printer.requestPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permission diperlukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final devices = await printer.getDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });

      if (devices.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada perangkat Bluetooth yang dipasangkan'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _connectToPrinter(Printer device) async {
    setState(() => _isLoading = true);

    final printer = BluetoothPrinterService.instance;
    final success = await printer.connect(device);

    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _selectedDevice = device;
        _isConnected = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terhubung ke ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal terhubung ke printer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectPrinter() async {
    final printer = BluetoothPrinterService.instance;
    await printer.disconnect();
    setState(() {
      _isConnected = false;
      _selectedDevice = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printer diputus'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Future<void> _saveSettings() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    await settings.updateSetting('wifi_password', _wifiPasswordController.text);
    await settings.updateSetting('daily_price', _dailyPriceController.text);
    await settings.updateSetting('monthly_price', _monthlyPriceController.text);
    await settings.updateSetting('receipt_header', _headerController.text);
    await settings.updateSetting('receipt_footer', _footerController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Printer settings
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.print, color: Color(0xFF2c3e50)),
                        const SizedBox(width: 12),
                        const Text(
                          'Printer Bluetooth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                        const Spacer(),
                        if (_isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Terhubung',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedDevice != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bluetooth_connected, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDevice!.name ?? 'Unknown Device',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _disconnectPrinter,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    CustomButton(
                      onPressed: _isLoading ? null : _scanDevices,
                      text: _isLoading ? 'Memindai...' : 'Cari Printer',
                      icon: Icons.bluetooth_searching,
                    ),
                    if (_devices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Perangkat yang Ditemukan:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.address ?? ''),
                            trailing: ElevatedButton(
                              onPressed: () => _connectToPrinter(device),
                              child: const Text('Hubungkan'),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // General settings
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.settings, color: Color(0xFF2c3e50)),
                        SizedBox(width: 12),
                        Text(
                          'Pengaturan Umum',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _wifiPasswordController,
                      label: 'Password WiFi',
                      icon: Icons.wifi,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _dailyPriceController,
                            label: 'Harga Harian',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _monthlyPriceController,
                            label: 'Harga Member',
                            icon: Icons.card_membership,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Format Struk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _headerController,
                      label: 'Header Struk',
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _footerController,
                      label: 'Footer Struk',
                      icon: Icons.text_fields,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      onPressed: _saveSettings,
                      text: 'Simpan Pengaturan',
                      icon: Icons.save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
