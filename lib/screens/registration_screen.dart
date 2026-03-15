import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
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
  String _registrationType = 'daily';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final now = DateTime.now();

      int? memberId;
      int price;

      if (_registrationType == 'monthly') {
        // Create member
        final member = Member(
          name: name,
          phone: phone.isEmpty ? null : phone,
          joinDate: now,
          expireDate: DateTime(now.year, now.month + 1, now.day),
          createdAt: now,
        );
        memberId = await memberProvider.addMember(member);
        price = settingsProvider.monthlyPrice;
      } else {
        price = settingsProvider.dailyPrice;
      }

      // Create transaction
      final transaction = Transaction(
        name: name,
        transactionType: _registrationType,
        price: price,
        checkInTime: now,
        memberId: memberId,
        createdAt: now,
      );
      await transactionProvider.addTransaction(transaction);

      // Show notification (skip if not initialized)
      try {
        await NotificationService.instance.showTransactionNotification(
          name: name,
          type: _registrationType,
          price: price,
        );
      } catch (e) {
        print('Notification error (skipped): $e');
      }

      // Show success dialog with print option
      if (!mounted) return;
      _showSuccessDialog(transaction, settingsProvider);

      // Reset form
      _nameController.clear();
      _phoneController.clear();
      setState(() => _registrationType = 'daily');
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

  void _showSuccessDialog(Transaction transaction, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrasi Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${transaction.name}'),
            Text('Tipe: ${transaction.typeLabel}'),
            Text('Harga: Rp ${_formatPrice(transaction.price)}'),
            const SizedBox(height: 16),
            const Text('Cetak struk?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _printReceipt(transaction, settings);
            },
            child: const Text('Cetak'),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(Transaction transaction, SettingsProvider settings) async {
    try {
      final printer = BluetoothPrinterService.instance;
      
      if (!await printer.isConnected()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer belum terhubung. Hubungkan di menu Pengaturan'),
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
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Registrasi'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: Color(0xFF2c3e50),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'MANSUR EXERCISE POINT',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2c3e50), Color(0xFF3c5470)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                // Form fields
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Nomor HP (Opsional)',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Type selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Paket',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeCard(
                              'daily',
                              'Harian',
                              'Rp ${_formatPrice(settings.dailyPrice)}',
                              Icons.today_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeCard(
                              'monthly',
                              'Member',
                              'Rp ${_formatPrice(settings.monthlyPrice)}',
                              Icons.card_membership_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Submit button
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey[400]!, Colors.grey[500]!]
                          : [const Color(0xFF2c3e50), const Color(0xFF3c5470)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoading ? Colors.grey : const Color(0xFF2c3e50)).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSubmit,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Daftarkan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String value, String title, String price, IconData icon) {
    final isSelected = _registrationType == value;

    return GestureDetector(
      onTap: () => setState(() => _registrationType = value),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF2c3e50), Color(0xFF3c5470)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[50],
            border: Border.all(
              color: isSelected ? const Color(0xFF2c3e50) : Colors.grey.shade300,
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : const Color(0xFF2c3e50),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
