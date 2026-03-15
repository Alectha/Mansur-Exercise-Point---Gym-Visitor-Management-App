import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'member_checkin_screen.dart';
import 'members_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RegistrationScreen(),
    const MemberCheckinScreen(),
    const MembersScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2c3e50),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 28),
            label: '',
          ),
        ],
      ),
    );
  }
}
