import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService instance =
      BluetoothPrinterService._init();

  final FlutterThermalPrinter _plugin = FlutterThermalPrinter.instance;
  Printer? _selectedPrinter;
  List<Printer> _printers = [];
  StreamSubscription<List<Printer>>? _devicesSubscription;

  BluetoothPrinterService._init() {
    _plugin.bleConfig = const BleConfig(
      connectionStabilizationDelay: Duration(seconds: 3),
    );
  }

  Future<bool> requestPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    return await Permission.bluetoothConnect.isGranted;
  }

  Future<List<Printer>> getDevices() async {
    final completer = Completer<List<Printer>>();

    _devicesSubscription?.cancel();
    await _plugin.getPrinters(connectionTypes: [
      ConnectionType.USB,
      ConnectionType.BLE,
    ]);

    _devicesSubscription = _plugin.devicesStream.listen((List<Printer> event) {
      _printers = event;
      if (!completer.isCompleted) {
        // Give it a moment to collect all devices, then resolve
        Future.delayed(const Duration(seconds: 3), () {
          if (!completer.isCompleted) {
            completer.complete(_printers);
          }
        });
      }
    });

    // Timeout after 6 seconds
    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => _printers,
    );
  }

  Stream<List<Printer>> get devicesStream => _plugin.devicesStream;

  Future<void> startScan() async {
    _devicesSubscription?.cancel();
    await _plugin.getPrinters(connectionTypes: [
      ConnectionType.USB,
      ConnectionType.BLE,
    ]);
  }

  void stopScan() {
    _plugin.stopScan();
    _devicesSubscription?.cancel();
  }

  Future<bool> connect(Printer printer) async {
    try {
      await _plugin.connect(printer);
      _selectedPrinter = printer;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_selectedPrinter != null) {
        await _plugin.disconnect(_selectedPrinter!);
      }
      _selectedPrinter = null;
    } catch (e) {
      _selectedPrinter = null;
    }
  }

  Future<bool> isConnected() async {
    return _selectedPrinter != null && (_selectedPrinter!.isConnected ?? false);
  }

  Printer? get selectedPrinter => _selectedPrinter;

  Future<void> printReceipt({
    required String header,
    required String name,
    required String type,
    required int price,
    required DateTime checkInTime,
    required String wifiPassword,
    required String footer,
  }) async {
    try {
      if (_selectedPrinter == null ||
          !(_selectedPrinter!.isConnected ?? false)) {
        throw Exception('Printer tidak terhubung');
      }

      final typeLabel = type == 'daily' ? 'Harian' : 'Member';
      final priceFormatted = 'Rp ${price.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )}';

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final logoBytes = await _loadReceiptLogoBytes();
      if (logoBytes != null) {
        bytes += generator.imageRaster(logoBytes, align: PosAlign.center);
        bytes += generator.feed(1);
      }

      // Header
      bytes += generator.text(
        header,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          // Mengurangi ukuran headline sesuai permintaan (dari size2 ke normal tapi bold)
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      );
      bytes += generator.hr();

      // Detail
      bytes += generator.row([
        PosColumn(text: 'Nama', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
            text: name,
            width: 8,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Tipe', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
            text: typeLabel,
            width: 8,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Harga', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
            text: priceFormatted,
            width: 8,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Waktu', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _formatDateTime(checkInTime),
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr();

      // WiFi password
      bytes += generator.text(
        'Password WiFi: $wifiPassword',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      bytes += generator.hr(ch: '-');

      // Footer
      bytes += generator.text(
        footer,
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.feed(2);
      bytes += generator.cut();

      await _plugin.printData(
        _selectedPrinter!,
        bytes,
        longData: true,
      );
    } catch (e) {
      throw Exception('Gagal mencetak: ${e.toString()}');
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

  Future<img.Image?> _loadReceiptLogoBytes() async {
    const candidatePaths = [
      'assets/images/receipt_icon.png',
      'assets/images/receipt_logo.png',
    ];

    for (final assetPath in candidatePaths) {
      try {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          continue;
        }

        final resized = img.copyResize(decoded, width: 256);
        final grayscale = img.grayscale(resized);
        return _ensureDivisibleBy8(grayscale);
      } catch (_) {
        // Skip missing/invalid asset and try next candidate.
      }
    }

    return null;
  }

  img.Image _ensureDivisibleBy8(img.Image image) {
    if (image.width % 8 == 0) {
      return image;
    }

    final nextDivisible = image.width + (8 - (image.width % 8));
    return img.copyResize(image, width: nextDivisible);
  }
}
