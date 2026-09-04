import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';

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

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("🥇 1-O'rin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    } else if (rank == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppTheme.silverGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("🥈 2-O'rin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    } else if (rank == 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppTheme.bronzeGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("🥉 3-O'rin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }
    return Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _leaderboards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text("Hali reyting ma'lumotlari mavjud emas.", style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _leaderboards.length,
                    itemBuilder: (ctx, idx) {
                      final board = _leaderboards[idx];
                      final rankings = board["rankings"] as List<dynamic>? ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ModernCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "${board["group_name"]} Reytingi",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              ...rankings.map((r) {
                                final isCurrent = r["is_current_student"] == true;
                                final rank = r["rank"] as int;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? AppTheme.primary.withOpacity(0.08) : AppTheme.bgLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isCurrent ? Border.all(color: AppTheme.primary, width: 1.5) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 84,
                                        child: _buildRankBadge(rank),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r["full_name"],
                                                style: TextStyle(
                                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                                  color: isCurrent ? AppTheme.primary : AppTheme.textDark,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (isCurrent)
                                              Container(
                                                margin: const EdgeInsets.only(right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  "Siz",
                                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "${r["total_points"]} ⭐",
                                        style: const TextStyle(fontWeight: FontWeight.extrabold, color: Colors.amber, fontSize: 16),
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
