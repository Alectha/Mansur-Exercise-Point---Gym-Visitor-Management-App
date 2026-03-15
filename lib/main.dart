import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/member_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_helper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize database
    await DatabaseHelper.instance.database;
    print('Database initialized successfully');
    
    // Initialize notification service
    await NotificationService.instance.initialize();
    print('Notification service initialized successfully');
  } catch (e, stackTrace) {
    print('Initialization error: $e');
    print('Stack trace: $stackTrace');
  }
  
  // Set portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Mansur Exercise Point',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          primaryColor: const Color(0xFF2c3e50),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2c3e50),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF2c3e50),
            elevation: 2,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2c3e50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2c3e50), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
