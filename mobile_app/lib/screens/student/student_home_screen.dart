import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'tests_list_screen.dart';
import 'leaderboard_screen.dart';
import 'market_screen.dart';
import 'student_stats_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getStudentDashboard();
    setState(() {
      _dashboardData = data["student"];
      _isLoading = false;
    });
  }

  void _logout() async {
    await ApiService.clearAuth();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_dashboardData == null) return const Center(child: Text("Ma'lumot topilmadi."));

    final student = _dashboardData!;
    final groups = student["groups"] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Points Card Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.purple.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.indigo.shade200, blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      student["full_name"],
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 36),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Sizning Umumiy Ballaringiz:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  "${student["total_points"]} ⭐",
                  style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Enrolled Groups
          const Text("Mening Guruhlarim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            const Text("Hali biror guruhga a'zo emassiz.", style: TextStyle(color: Colors.grey))
          else
            ...groups.map((g) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Colors.indigo),
                    title: Text(g["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("O'qituvchi: ${g["teacher_name"]}"),
                  ),
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildOverviewTab(),
      const TestsListScreen(),
      const LeaderboardScreen(),
      const MarketScreen(),
      const StudentStatsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("O'quvchi Kabineti"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo.shade900,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Bosh sahifa"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Testlar"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Reyting"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Do'kon"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistika"),
        ],
      ),
    );
  }
}
