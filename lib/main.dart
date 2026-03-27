import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
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
        themeMode: ThemeMode.dark, // Force dark theme
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4FC3F7), // Soft blue accent
            secondary: Color(0xFF81D4FA),
            surface: Color(0xFF1E1E1E), // Dark grey surface
            background: Color(0xFF121212), // Dark grey background
            onPrimary: Colors.black,
            onSurface: Colors.white,
            onBackground: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF333333), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
            floatingLabelStyle: const TextStyle(
                color: Color(0xFF4FC3F7),
                fontWeight: FontWeight.bold,
                fontSize: 16),
            hintStyle: const TextStyle(color: Color(0xFF777777)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            selectedItemColor: Color(0xFF4FC3F7),
            unselectedItemColor: Color(0xFF757575),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
