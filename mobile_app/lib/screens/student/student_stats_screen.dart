import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class StudentStatsScreen extends StatefulWidget {
  const StudentStatsScreen({super.key});

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getStudentStats();
    setState(() {
      _statsData = data;
      _isLoading = false;
    });
  }

  Widget _buildStatCard(String title, Map<String, dynamic> data, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  "$title Statistika",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Ball", "${data["points"]} ⭐", Colors.amber.shade800),
                _buildStatItem("Keldi", "${data["present"]} kun", Colors.green.shade700),
                _buildStatItem("Kelmadi", "${data["absent"]} kun", Colors.red.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_statsData == null) return const Center(child: Text("Statistika ma'lumotlari topilmadi."));

    final periods = _statsData!["periods"] as Map<String, dynamic>? ?? {};
    final monthly = periods["monthly"] as Map<String, dynamic>? ?? {};
    final weekly = periods["weekly"] as Map<String, dynamic>? ?? {};
    final overall = periods["overall"] as Map<String, dynamic>? ?? {};

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard("Oylik", monthly, Icons.calendar_month, Colors.indigo),
            _buildStatCard("Haftalik", weekly, Icons.date_range, Colors.teal),
            _buildStatCard("Umumiy", overall, Icons.insights, Colors.purple),
          ],
        ),
      ),
    );
  }
}
