import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MarketManagementScreen extends StatefulWidget {
  const MarketManagementScreen({super.key});

  @override
  State<MarketManagementScreen> createState() => _MarketManagementScreenState();
}

class _MarketManagementScreenState extends State<MarketManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _items = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await ApiService.getTeacherMarketItems();
    final orders = await ApiService.getTeacherMarketOrders();
    setState(() {
      _items = items;
      _orders = orders;
      _isLoading = false;
    });
  }

  void _showAddItemDialog() {
    final titleCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "1");
    final discountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgUrlCtrl = TextEditingController();
    String itemType = "product";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yangi Mahsulot / Chegirma Yaratish"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: "product", label: Text("Mahsulot")),
                    ButtonSegment(value: "discount", label: Text("Chegirma")),
                  ],
                  selected: {itemType},
                  onSelectionChanged: (val) => setDialogState(() => itemType = val.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Nomi (masalan: Ruchka yoki 10% Chegirma)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Narxi (Ballarda ⭐)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Miqdori (Dona)"),
                ),
                if (itemType == "discount") ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Chegirma foizi (masalan: 10)"),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: imgUrlCtrl,
                  decoration: const InputDecoration(labelText: "Rasm Havolasi (URL)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: "Tavsif / Izoh"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton(
              onPressed: () async {
                final cost = int.tryParse(costCtrl.text.trim()) ?? 0;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                final disc = int.tryParse(discountCtrl.text.trim());

                if (titleCtrl.text.trim().isNotEmpty && cost > 0) {
                  await ApiService.createMarketItem(
                    titleCtrl.text.trim(),
                    itemType,
                    cost,
                    qty,
                    disc,
                    descCtrl.text.trim(),
                    imgUrlCtrl.text.trim().isNotEmpty ? imgUrlCtrl.text.trim() : null,
                  );
                  if (mounted) Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text("Yaratish"),
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrderStatus(int orderId, String newStatus) async {
    await ApiService.updateOrderStatus(orderId, newStatus);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.indigo.shade900,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo.shade900,
            tabs: const [
              Tab(icon: Icon(Icons.storefront), text: "Mahsulotlar"),
              Tab(icon: Icon(Icons.shopping_cart), text: "Buyurtmalar"),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Items Tab
                      _items.isEmpty
                          ? const Center(child: Text("Hali mahsulotlar yaratilmagan."))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              itemBuilder: (ctx, idx) {
                                final item = _items[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo.shade50,
                                      child: Icon(
                                        item["item_type"] == "discount" ? Icons.discount : Icons.card_giftcard,
                                        color: Colors.indigo.shade900,
                                      ),
                                    ),
                                    title: Text(item["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Narxi: ${item["points_cost"]} ⭐ | Qoldiq: ${item["quantity"]} ta"),
                                    trailing: Chip(
                                      label: Text(item["is_active"] ? "Faol" : "Noaktiv"),
                                      backgroundColor: item["is_active"] ? Colors.green.shade50 : Colors.grey.shade200,
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Orders Tab
                      _orders.isEmpty
                          ? const Center(child: Text("Hali xarid buyurtmalari yo'q."))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (ctx, idx) {
                                final order = _orders[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text("${order["student_name"]} ➔ ${order["item_title"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Sarflandi: ${order["points_spent"]} ⭐ | Vaqt: ${order["created_at"]}"),
                                    trailing: DropdownButton<String>(
                                      value: order["status"],
                                      items: const [
                                        DropdownMenuItem(value: "pending", child: Text("Kutilmoqda")),
                                        DropdownMenuItem(value: "approved", child: Text("Tasdiqlandi")),
                                        DropdownMenuItem(value: "delivered", child: Text("Topshirildi")),
                                        DropdownMenuItem(value: "cancelled", child: Text("Bekor qilindi")),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          _updateOrderStatus(order["id"], val);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text("Yangi Mahsulot"),
      ),
    );
  }
}
