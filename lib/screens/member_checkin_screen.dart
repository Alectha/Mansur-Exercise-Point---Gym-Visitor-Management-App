import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
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
          content: Text('Member sudah kadaluarsa! Silakan perpanjang membership'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      final transaction = Transaction(
        name: member.name,
        transactionType: 'monthly',
        price: 0, // Member check-in is free
        checkInTime: DateTime.now(),
        memberId: member.id,
        createdAt: DateTime.now(),
      );

      await transactionProvider.addTransaction(transaction);

      // Show notification
      await NotificationService.instance.showTransactionNotification(
        name: member.name,
        type: 'monthly',
        price: 0,
      );

      if (!mounted) return;
      _showSuccessDialog(transaction, settingsProvider);

      // Clear search
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${transaction.name}'),
            Text('Waktu: ${_formatDateTime(transaction.checkInTime)}'),
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

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Color _getDaysRemainingColor(int days) {
    if (days > 7) return Colors.green;
    if (days >= 4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Check-in Member'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Modern search bar
              Container(
                height: 56,
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _searchMembers(),
                        decoration: InputDecoration(
                          hintText: 'Cari nama member...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: const Color(0xFF2c3e50),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _searchMembers,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isSearching)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Member tidak ditemukan',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                Expanded(
                  child: Container(
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
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final member = _searchResults[index];
                        final daysRemaining = member.daysRemaining;
                        final color = _getDaysRemainingColor(daysRemaining);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2c3e50), Color(0xFF3c5470)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  member.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 13,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    member.phone ?? '-',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.15),
                                        color.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: color, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        member.isExpired ? Icons.error_outline : Icons.schedule,
                                        size: 11,
                                        color: color,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        member.isExpired ? 'Expired' : '$daysRemaining hari',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Material(
                                  color: const Color(0xFF2c3e50),
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    onTap: () => _checkInMember(member),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.login, size: 18, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'Check-in',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2c3e50).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Cari member untuk check-in',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan nama pada kolom pencarian',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
