import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getLeaderboard();
    setState(() {
      _leaderboards = data;
      _isLoading = false;
    });
  }

  String _getRankEmoji(int rank) {
    if (rank == 1) return "🥇";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "#$rank";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboards.isEmpty
              ? const Center(child: Text("Reyting ma'lumotlari topilmadi."))
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaderboards.length,
                    itemBuilder: (ctx, idx) {
                      final board = _leaderboards[idx];
                      final rankings = board["rankings"] as List<dynamic>? ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${board["group_name"]} Reytingi",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              ...rankings.map((r) {
                                final isCurrent = r["is_current_student"] == true;
                                final rankStr = _getRankEmoji(r["rank"]);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? Colors.amber.shade50 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isCurrent ? Border.all(color: Colors.amber.shade700, width: 2) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          rankStr,
                                          style: TextStyle(
                                            fontSize: r["rank"] <= 3 ? 20 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          r["full_name"],
                                          style: TextStyle(
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            color: isCurrent ? Colors.indigo.shade900 : Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(6)),
                                          child: const Text("Siz", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      Text(
                                        "${r["total_points"]} ⭐",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
