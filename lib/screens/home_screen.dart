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

  final List<String> _tabLabels = [
    'Daftar',
    'Check-in',
    'Member',
    'Laporan',
    'Setelan'
  ];

  final List<IconData> _tabIcons = [
    Icons.person_add_rounded,
    Icons.login_rounded,
    Icons.people_alt_rounded,
    Icons.assessment_rounded,
    Icons.settings_rounded,
  ];

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
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark surface
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuint,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4FC3F7).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabIcons[index],
                          color: isSelected
                              ? const Color(0xFF4FC3F7) // Soft blue
                              : const Color(0xFF757575), // Grey
                          size: 24,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            _tabLabels[index],
                            style: const TextStyle(
                              color: Color(0xFF4FC3F7),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
