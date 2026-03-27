import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request notification permission for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showTransactionNotification({
    required String name,
    required String type,
    required int price,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'transaction_channel',
      'Transaksi',
      channelDescription: 'Notifikasi untuk transaksi dan check-in',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@drawable/ic_notification',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final typeLabel = type == 'daily' ? 'Harian' : 'Member';
    final priceFormatted = 'Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Check-in Berhasil',
      '$name ($typeLabel) - $priceFormatted',
      notificationDetails,
    );
  }
}
