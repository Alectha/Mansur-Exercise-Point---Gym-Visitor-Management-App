import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_helper.dart';
import '../providers/transaction_provider.dart';
import '../providers/member_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as tr;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadTransactions();
    });
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
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

  Future<void> _selectDate(BuildContext context) async {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final picked = await showDatePicker(
        context: context,
        initialDate: transactionProvider.selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4FC3F7),
                onPrimary: Colors.black,
                surface: Color(0xFF2C2C2C),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        });
    if (picked != null) {
      transactionProvider.setDate(picked);
      setState(() => _currentPage = 0);
    }
  }

  List<BarChartGroupData> _buildChartData(
      List<tr.Transaction> transactions, DateTime selectedDate) {
    // Generate daily totals for the week containing selectedDate
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final dailyTotals = List.generate(7, (index) => 0);

    for (var tx in transactions) {
      if (tx.createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          tx.createdAt.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        final dayIndex = tx.createdAt.weekday - 1;
        dailyTotals[dayIndex] += tx.price;
      }
    }

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[index].toDouble() /
                1000, // In thousands for better display
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY:
                  dailyTotals.reduce((a, b) => a > b ? a : b).toDouble() / 1000,
              color: const Color(0xFF2C2C2C),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _exportDatabase() async {
    try {
      final dbPath = await DatabaseHelper.instance.getFullDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        final xFile = XFile(dbPath, name: 'mansur_gym_backup.db');
        await Share.shareXFiles([xFile], text: 'Backup Data Mansur Gym');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('File database tidak ditemukan'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mengekspor: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;

        if (!selectedPath.endsWith('.db') &&
            !selectedPath.endsWith('.sqlite')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Format file harus berupa .db / .sqlite!'),
                backgroundColor: Colors.red),
          );
          return;
        }

        bool confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Konfirmasi File Restore',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                content: const Text(
                    'Semua data saat ini akan ditimpa dengan data dari file backup. Apakah Anda yakin?',
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal',
                        style: TextStyle(color: Color(0xFF4FC3F7))),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya, Timpa Data'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!confirm) return;

        await DatabaseHelper.instance.replaceDatabase(selectedPath);

        if (!mounted) return;
        Provider.of<TransactionProvider>(context, listen: false)
            .loadTransactions();
        Provider.of<MemberProvider>(context, listen: false).loadMembers();
        Provider.of<SettingsProvider>(context, listen: false).loadSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data berhasil di-restore!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal melakukan impor: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Laporan & Analisis',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF4FC3F7)),
            tooltip: 'Eksport (Backup Data)',
            onPressed: _exportDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.upload, color: Color(0xFF4FC3F7)),
            tooltip: 'Import (Timpa Data)',
            onPressed: _importDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded,
                color: Color(0xFF4FC3F7)),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final totalIncome =
              provider.getTotalIncomeForDate(provider.selectedDate);
          final transactions =
              provider.getTransactionsForDate(provider.selectedDate);
          final totalCheckins = provider.transactions
              .where((t) =>
                  t.transactionType == 'Check-in Member' &&
                  t.createdAt.year == provider.selectedDate.year &&
                  t.createdAt.month == provider.selectedDate.month &&
                  t.createdAt.day == provider.selectedDate.day)
              .length;

          // Pagination logic
          final startIndex = _currentPage * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage;
          final paginatedTransactions = transactions.sublist(
            startIndex,
            endIndex > transactions.length ? transactions.length : endIndex,
          );
          final totalPages = (transactions.length / _itemsPerPage).ceil();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF333333)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${provider.selectedDate.day}/${provider.selectedDate.month}/${provider.selectedDate.year}',
                              style: const TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Total Pendapatan',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${_formatPrice(totalIncome)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4FC3F7),
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMiniStatCard(
                                    'Transaksi',
                                    '${transactions.length}',
                                    Icons.receipt_long_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMiniStatCard(
                                    'Check-in',
                                    '$totalCheckins',
                                    Icons.how_to_reg_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Grafik Mingguan (Ribuan Rupiah)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.only(
                            top: 24, right: 16, left: 8, bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: totalIncome > 0
                            ? BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: provider.transactions.isEmpty
                                      ? 100
                                      : null,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipPadding: const EdgeInsets.all(8),
                                      tooltipMargin: 8,
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          rod.toY.round().toString(),
                                          const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          const days = [
                                            'Sen',
                                            'Sel',
                                            'Rab',
                                            'Kam',
                                            'Jum',
                                            'Sab',
                                            'Min'
                                          ];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              days[value.toInt()],
                                              style: const TextStyle(
                                                  color: Color(0xFF757575),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _buildChartData(
                                      provider.transactions,
                                      provider.selectedDate),
                                ),
                              )
                            : const Center(
                                child: Text('Tidak ada data minggu ini',
                                    style: TextStyle(color: Color(0xFF757575))),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Riwayat Transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${transactions.length} Total',
                            style: const TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long_rounded,
                            size: 64, color: Color(0xFF333333)),
                        SizedBox(height: 16),
                        Text('Belum ada transaksi hari ini',
                            style: TextStyle(color: Color(0xFF757575))),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = paginatedTransactions[index];
                        final isCheckIn =
                            tx.transactionType == 'Check-in Member';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2C2C2C)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isCheckIn
                                    ? const Color(0xFF4FC3F7).withOpacity(0.1)
                                    : Colors.greenAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCheckIn
                                    ? Icons.how_to_reg_rounded
                                    : Icons.payments_rounded,
                                color: isCheckIn
                                    ? const Color(0xFF4FC3F7)
                                    : Colors.greenAccent,
                              ),
                            ),
                            title: Text(
                              tx.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(tx.transactionType,
                                    style: const TextStyle(
                                        color: Color(0xFFAAAAAA),
                                        fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(_formatDateTime(tx.createdAt),
                                    style: const TextStyle(
                                        color: Color(0xFF757575),
                                        fontSize: 12)),
                              ],
                            ),
                            trailing: Text(
                              isCheckIn ? '-' : 'Rp ${_formatPrice(tx.price)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isCheckIn
                                    ? const Color(0xFF757575)
                                    : Colors.greenAccent,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: paginatedTransactions.length,
                    ),
                  ),
                ),
              if (totalPages > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        Text(
                          'Halaman ${_currentPage + 1} dari $totalPages',
                          style: const TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                          onPressed: _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: 80)), // Bottom padding
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4FC3F7), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
