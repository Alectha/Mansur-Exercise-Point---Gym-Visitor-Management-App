import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../models/registration_package.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_printer_service.dart';
import '../widgets/custom_textfield.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  RegistrationPackage? _selectedPackage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih paket pendaftaran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final memberProvider =
          Provider.of<MemberProvider>(context, listen: false);

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final now = DateTime.now();

      int? memberId;
      int price = _selectedPackage!.price;

      // Automatically create member if it's a monthly program type or any custom logic?
      // For dynamic packages, we might not always know if it's a 1-month member, but to keep old behavior, let's say we create a member for every purchase that isn't simple daily. Or maybe create member for all? Let's just create Member object so they are tracked, default to 30 days active for any package (or you can customize later).
      final member = Member(
        name: name,
        phone: phone.isEmpty ? null : phone,
        joinDate: now,
        expireDate: DateTime(now.year, now.month + 1, now.day),
        createdAt: now,
      );
      memberId = await memberProvider.addMember(member);

      // Create transaction
      final transaction = Transaction(
        name: name,
        transactionType: _selectedPackage!.name,
        price: price,
        checkInTime: now,
        memberId: memberId,
        createdAt: now,
      );
      await transactionProvider.addTransaction(transaction);

      if (!mounted) return;
      _showSuccessBottomSheet(transaction, settingsProvider);

      // Reset form
      _nameController.clear();
      _phoneController.clear();
      setState(() => _selectedPackage = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessBottomSheet(
      Transaction transaction, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E), // Dark Theme
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4FC3F7).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registrasi Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nama',
                              style: TextStyle(color: Color(0xFFAAAAAA))),
                          Text(transaction.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paket',
                              style: TextStyle(color: Color(0xFFAAAAAA))),
                          Text(transaction.transactionType,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF404040)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(
                            'Rp ${_formatPrice(transaction.price)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color(0xFF4FC3F7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _printReceipt(transaction, settings);
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Cetak Struk',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(
      Transaction transaction, SettingsProvider settings) async {
    try {
      final printer = BluetoothPrinterService.instance;

      if (!await printer.isConnected()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Printer belum terhubung. Hubungkan di menu Pengaturan'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await printer.printReceipt(
        header: settings.receiptHeader,
        name: transaction.name,
        type: transaction.transactionType,
        price: transaction.price,
        checkInTime: transaction.checkInTime,
        wifiPassword: settings.wifiPassword,
        footer: settings.receiptFooter,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Struk berhasil dicetak'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '\.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'MANSUR EXERCISE POINT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Form fields
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Diri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0E0E0),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _nameController,
                            label: 'Nama Lengkap',
                            icon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Nomor HP (Opsional)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Type selection
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Paket',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0E0E0),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (settingsProvider.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (settingsProvider.packages.isEmpty)
                            const Center(
                              child: Text(
                                'Belum ada paket tersedia.\nTambahkan di menu Pengaturan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: settingsProvider.packages.length,
                              itemBuilder: (context, index) {
                                final pkg = settingsProvider.packages[index];
                                return _buildTypeCard(pkg);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Submit button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                              ),
                        color: _isLoading ? const Color(0xFF333333) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4FC3F7).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleSubmit,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded,
                                          color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Daftarkan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(RegistrationPackage package) {
    final isSelected = _selectedPackage?.id == package.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPackage = package);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4FC3F7).withOpacity(0.1)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4FC3F7) : const Color(0xFF333333),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4FC3F7), size: 20),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4FC3F7)
                          : const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded, // default icon
                      color:
                          isSelected ? Colors.white : const Color(0xFF757575),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    package.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFFCCCCCC),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice(package.price)}',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4FC3F7)
                          : const Color(0xFF757575),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
