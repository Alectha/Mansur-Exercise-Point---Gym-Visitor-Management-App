import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _period = 'daily';
  DateTime _selectedDate = DateTime.now();

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get period => _period;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await DatabaseHelper.instance.getTransactions(
      period: _period,
      date: _selectedDate,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<int> addTransaction(Transaction transaction) async {
    final id = await DatabaseHelper.instance.createTransaction(transaction);
    await loadTransactions();
    return id;
  }

  void setPeriod(String period) {
    _period = period;
    loadTransactions();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    loadTransactions();
  }

  int get totalRevenue {
    return _transactions.fold(0, (sum, transaction) => sum + transaction.price);
  }

  int get dailyCount {
    return _transactions.where((t) => t.transactionType == 'daily').length;
  }

  int get memberCount {
    return _transactions.where((t) => t.transactionType == 'monthly').length;
  }
}
