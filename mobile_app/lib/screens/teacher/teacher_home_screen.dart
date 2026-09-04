import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'groups_screen.dart';
import 'attendance_screen.dart';
import 'students_screen.dart';
import 'market_management_screen.dart';
import 'tests_management_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    GroupsScreen(),
    AttendanceScreen(),
    StudentsScreen(),
    MarketManagementScreen(),
    TestsManagementScreen(),
  ];

  final List<String> _titles = const [
    "Guruhlar boshqaruvi",
    "Kunlik Davomat",
    "O'quvchilar ro'yxati",
    "Do'kon Sozlamalari",
    "Testlar & Nazorat",
  ];

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tizimdan chiqish"),
        content: const Text("Haqiqatan ham kabinetdan chiqmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Bekor qilish", style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text("Chiqish"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearAuth();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppTheme.textDark),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            tooltip: "Chiqish",
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Colors.white,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                activeIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primary),
                label: "Guruhlar",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rule_rounded),
                activeIcon: Icon(Icons.rule_rounded, color: AppTheme.primary),
                label: "Davomat",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                activeIcon: Icon(Icons.people_alt_rounded, color: AppTheme.primary),
                label: "O'quvchilar",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront_rounded),
                activeIcon: Icon(Icons.storefront_rounded, color: AppTheme.primary),
                label: "Do'kon",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz_rounded),
                activeIcon: Icon(Icons.quiz_rounded, color: AppTheme.primary),
                label: "Testlar",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
