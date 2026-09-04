import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/primary_button.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _studentPoints = 0;
  List<dynamic> _items = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getStudentMarketItems();
    final orders = await ApiService.getStudentOrders();

    setState(() {
      _studentPoints = data["student_points"] ?? 0;
      _items = data["items"] ?? [];
      _orders = orders;
      _isLoading = false;
    });
  }

  void _buyItem(int itemId, String title, int cost) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xaridni Tasdiqlash"),
        content: Text("\"$title\" mahsulotini $cost ⭐ evaziga xarid qilasizmi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Bekor qilish", style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Xarid qilish"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.buyMarketItem(itemId);

    if (res.containsKey("error")) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["error"]), backgroundColor: AppTheme.danger),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Muvaffaqiyatli xarid qilindi!"), backgroundColor: AppTheme.success),
      );
      _loadMarketData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadMarketData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Balance Card
                  GradientCard(
                    gradient: AppTheme.goldGradient,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 32),
                            SizedBox(width: 12),
                            Text(
                              "Mavjud Balans",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          "$_studentPoints ⭐",
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Do'kon Mahsulotlari",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    ModernCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              const Text("Hozircha do'konda faol mahsulotlar yo'q", style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.map((item) {
                      final canAfford = item["can_afford"] == true;
                      final cost = item["points_cost"];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ModernCard(
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  item["item_type"] == "discount" ? Icons.local_offer_rounded : Icons.card_giftcard_rounded,
                                  color: AppTheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAlignment.start,
                                  children: [
                                    Text(
                                      item["title"],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Narxi: $cost ⭐ • Qoldiq: ${item["quantity"]} ta",
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: canAfford ? () => _buyItem(item["id"], item["title"], cost) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canAfford ? AppTheme.success : Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Xarid", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  const Text(
                    "Mening Xaridlarim",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 12),

                  if (_orders.isEmpty)
                    const Text("Hali xaridlaringiz yo'q.", style: TextStyle(color: AppTheme.textMuted))
                  else
                    ..._orders.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ModernCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded, color: AppTheme.primary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o["item_title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text("-${o["points_spent"]} ⭐", style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: o["status"] == "approved"
                                        ? AppTheme.success.withOpacity(0.1)
                                        : AppTheme.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    o["status"] == "approved" ? "Tasdiqlangan" : "Kutilmoqda",
                                    style: TextStyle(
                                      color: o["status"] == "approved" ? AppTheme.success : AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
