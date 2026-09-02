import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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

  void _logout() async {
    await ApiService.clearAuth();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("O'qituvchi Kabineti"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Chiqish",
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo.shade900,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Guruhlar"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "Davomat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "O'quvchilar"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: "Do'kon"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Testlar"),
        ],
      ),
    );
  }
}
