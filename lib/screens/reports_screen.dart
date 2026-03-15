import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../widgets/summary_card.dart';

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
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
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
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: transactionProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      transactionProvider.setDate(picked);
      setState(() => _currentPage = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
              setState(() => _currentPage = 0);
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = transactionProvider.transactions;
          final totalPages = (transactions.length / _itemsPerPage).ceil();
          final startIndex = _currentPage * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage).clamp(0, transactions.length);
          final displayedTransactions = transactions.sublist(
            startIndex,
            endIndex,
          );

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Periode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPeriodButton('daily', 'Harian'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPeriodButton('weekly', 'Mingguan'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPeriodButton('monthly', 'Bulanan'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatDateTime(transactionProvider.selectedDate).split(' ')[0],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary cards - no full animation, just data update
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Total Pendapatan',
                          value: 'Rp ${_formatPrice(transactionProvider.totalRevenue)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SummaryCard(
                          title: 'Pengunjung Harian',
                          value: transactionProvider.dailyCount.toString(),
                          icon: Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Member Check-in',
                          value: transactionProvider.memberCount.toString(),
                          icon: Icons.card_membership,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SummaryCard(
                          title: 'Total Transaksi',
                          value: transactions.length.toString(),
                          icon: Icons.receipt,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chart
                  if (transactions.isNotEmpty) ...[
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
                            const Text(
                              'Grafik Pendapatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 250,
                              child: _buildRevenueChart(transactions),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Transaction list
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
                          const Text(
                            'Daftar Transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (transactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Belum ada transaksi',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayedTransactions.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final transaction = displayedTransactions[index];
                                final absoluteIndex = startIndex + index + 1;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: transaction.transactionType == 'daily'
                                        ? Colors.blue
                                        : Colors.orange,
                                    child: Text(
                                      absoluteIndex.toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    transaction.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(_formatDateTime(transaction.checkInTime)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        transaction.typeLabel,
                                        style: TextStyle(
                                          color: transaction.transactionType == 'daily'
                                              ? Colors.blue
                                              : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (transaction.price > 0)
                                        Text(
                                          'Rp ${_formatPrice(transaction.price)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (totalPages > 1) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                  ),
                                  Text(
                                    'Halaman ${_currentPage + 1} dari $totalPages',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < totalPages - 1
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final isSelected = transactionProvider.period == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: () {
          transactionProvider.setPeriod(value);
          setState(() => _currentPage = 0);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF2c3e50) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF2c3e50),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: isSelected ? 4 : 0,
          shadowColor: isSelected ? const Color(0xFF2c3e50).withOpacity(0.3) : Colors.transparent,
          side: BorderSide(
            color: const Color(0xFF2c3e50),
            width: isSelected ? 0 : 1,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2c3e50),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List transactions) {
    // Group transactions by date and calculate revenue
    final Map<String, int> revenueByDate = {};
    for (var transaction in transactions) {
      final date = transaction.checkInTime.toIso8601String().split('T')[0];
      revenueByDate[date] = ((revenueByDate[date] ?? 0) + transaction.price).toInt();
    }

    final spots = revenueByDate.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatPrice(value.toInt()),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < revenueByDate.length) {
                  final date = revenueByDate.keys.toList()[value.toInt()];
                  return Text(
                    date.split('-')[2],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2c3e50),
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2c3e50).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
