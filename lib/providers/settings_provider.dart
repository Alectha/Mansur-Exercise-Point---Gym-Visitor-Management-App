import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/registration_package.dart';

class SettingsProvider extends ChangeNotifier {
  Map<String, String> _settings = {};
  List<RegistrationPackage> _packages = [];
  bool _isLoading = false;

  Map<String, String> get settings => _settings;
  List<RegistrationPackage> get packages => _packages;
  bool get isLoading => _isLoading;

  String get wifiPassword => _settings['wifi_password'] ?? '';
  int get monthlyPrice =>
      int.tryParse(_settings['monthly_price'] ?? '300000') ?? 300000;
  String get receiptHeader =>
      _settings['receipt_header'] ?? 'MANSUR EXERCISE POINT';
  String get receiptFooter =>
      _settings['receipt_footer'] ?? 'Terima Kasih & Selamat Berolahraga!';

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await DatabaseHelper.instance.getAllSettings();
    _packages = await DatabaseHelper.instance.getPackages();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSetting(String key, String value) async {
    await DatabaseHelper.instance.updateSetting(key, value);
    await loadSettings();
  }

  Future<void> addPackage(RegistrationPackage package) async {
    await DatabaseHelper.instance.createPackage(package);
    await loadSettings();
  }

  Future<void> updatePackage(RegistrationPackage package) async {
    await DatabaseHelper.instance.updatePackage(package);
    await loadSettings();
  }

  Future<void> deletePackage(int id) async {
    await DatabaseHelper.instance.deletePackage(id);
    await loadSettings();
  }
}
