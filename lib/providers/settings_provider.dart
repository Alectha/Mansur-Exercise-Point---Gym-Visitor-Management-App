import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  Map<String, String> _settings = {};
  bool _isLoading = false;

  Map<String, String> get settings => _settings;
  bool get isLoading => _isLoading;

  String get wifiPassword => _settings['wifi_password'] ?? '';
  int get dailyPrice => int.tryParse(_settings['daily_price'] ?? '15000') ?? 15000;
  int get monthlyPrice => int.tryParse(_settings['monthly_price'] ?? '300000') ?? 300000;
  String get receiptHeader => _settings['receipt_header'] ?? 'MANSUR EXERCISE POINT';
  String get receiptFooter => _settings['receipt_footer'] ?? 'Terima Kasih & Selamat Berolahraga!';

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await DatabaseHelper.instance.getAllSettings();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSetting(String key, String value) async {
    await DatabaseHelper.instance.updateSetting(key, value);
    await loadSettings();
  }
}
