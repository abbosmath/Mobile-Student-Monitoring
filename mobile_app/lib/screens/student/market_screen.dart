import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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
        title: const Text("Xaridni Tasdiqlash"),
        content: Text("Rostdan ham \"$title\" mahsulotini $cost ⭐ ga xarid qilmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Yo'q")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900, foregroundColor: Colors.white),
            child: const Text("Ha, Xarid qilish"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.buyMarketItem(itemId);

    if (res.containsKey("error")) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["error"]), backgroundColor: Colors.red),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Muvaffaqiyatli xarid qilindi!"), backgroundColor: Colors.green),
      );
      _loadMarketData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMarketData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text("Do'kon Balansi", style: TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                        Text("$_studentPoints ⭐", style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Mavjud Mahsulot va Chegirmalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    const Text("Hozircha do'konda faol mahsulotlar yo'q.", style: TextStyle(color: Colors.grey))
                  else
                    ..._items.map((item) {
                      final canAfford = item["can_afford"] == true;
                      final cost = item["points_cost"];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Icon(item["item_type"] == "discount" ? Icons.local_offer : Icons.card_giftcard, color: Colors.indigo.shade900, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item["title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text("Narxi: $cost ⭐ | Qoldiq: ${item["quantity"]} ta"),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: canAfford ? () => _buyItem(item["id"], item["title"], cost) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text("Xarid"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  const Text("Mening Xaridlarim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_orders.isEmpty)
                    const Text("Hali xaridlaringiz yo'q.", style: TextStyle(color: Colors.grey))
                  else
                    ..._orders.map((o) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.history, color: Colors.indigo),
                            title: Text(o["item_title"], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Sarflandi: ${o["points_spent"]} ⭐ | Holat: ${o["status"]}"),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
