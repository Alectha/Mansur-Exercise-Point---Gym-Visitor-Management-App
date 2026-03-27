import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_printer_service.dart';

class MemberCheckinScreen extends StatefulWidget {
  const MemberCheckinScreen({Key? key}) : super(key: key);

  @override
  State<MemberCheckinScreen> createState() => _MemberCheckinScreenState();
}

class _MemberCheckinScreenState extends State<MemberCheckinScreen> {
  final _searchController = TextEditingController();
  List<Member> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMembers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final results = await memberProvider.searchMembers(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _checkInMember(Member member) async {
    if (member.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Member sudah kadaluarsa! Silakan perpanjang membership'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      final transaction = Transaction(
        name: member.name,
        transactionType: 'Check-in Member',
        price: 0,
        checkInTime: DateTime.now(),
        memberId: member.id,
        createdAt: DateTime.now(),
      );

      await transactionProvider.addTransaction(transaction);

      if (!mounted) return;
      _showSuccessDialog(transaction, settingsProvider);

      _searchController.clear();
      setState(() => _searchResults = []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(Transaction transaction, SettingsProvider settings) {
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
                'Check-in Berhasil!',
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
                        const Text('Waktu',
                            style: TextStyle(color: Color(0xFFAAAAAA))),
                        Text(_formatDateTime(transaction.checkInTime),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Check-in Member',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama member...',
                        hintStyle: TextStyle(color: Color(0xFF757575)),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Color(0xFF757575)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onSubmitted: (_) => _searchMembers(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: ElevatedButton(
                      onPressed: _searchMembers,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cari',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_searchResults.isEmpty &&
                _searchController.text.isNotEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 80, color: Color(0xFF333333)),
                      SizedBox(height: 16),
                      Text('Member tidak ditemukan',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xFF757575))),
                    ],
                  ),
                ),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _searchResults[index];
                    final isExpired = member.isExpired;

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isExpired
                              ? Colors.red.withOpacity(0.2)
                              : const Color(0xFF4FC3F7).withOpacity(0.2),
                          foregroundColor:
                              isExpired ? Colors.red : const Color(0xFF4FC3F7),
                          child: Text(member.name[0].toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(member.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        subtitle: Text(
                          isExpired
                              ? 'Status: Kadaluarsa'
                              : 'Aktif hingga: ${member.expireDate.day}/${member.expireDate.month}/${member.expireDate.year}',
                          style: TextStyle(
                              color: isExpired
                                  ? Colors.redAccent
                                  : const Color(0xFF81D4FA),
                              fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed:
                              isExpired ? null : () => _checkInMember(member),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpired
                                ? const Color(0xFF333333)
                                : const Color(0xFF4FC3F7),
                            foregroundColor: isExpired
                                ? const Color(0xFF757575)
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: const Text('Check-in',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
