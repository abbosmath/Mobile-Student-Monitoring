import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await ApiService.getTeacherStudents();
    setState(() {
      _students = students;
      _filteredStudents = students;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStudents = _students);
    } else {
      setState(() {
        _filteredStudents = _students.where((st) {
          final name = st["full_name"].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final tgCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yangi O'quvchi Qo'shish"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "O'quvchi F.I.Sh"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: parentCtrl,
                decoration: const InputDecoration(labelText: "Ota-onasi F.I.Sh"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tgCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Parent Telegram ID"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Telefon raqami"),
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
              if (nameCtrl.text.trim().isNotEmpty) {
                await ApiService.createStudent(
                  nameCtrl.text.trim(),
                  parentCtrl.text.trim(),
                  tgCtrl.text.trim(),
                  phoneCtrl.text.trim(),
                  null,
                );
                if (mounted) Navigator.pop(ctx);
                _loadStudents();
              }
            },
            child: const Text("Qo'shish"),
          ),
        ],
      ),
    );
  }

  void _showAdjustPointsDialog(int studentId, String studentName) {
    final pointsCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    String action = "give";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Ball berish / olib tashlash ($studentName)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "give", label: Text("+ Ball Berish"), icon: Icon(Icons.add)),
                  ButtonSegment(value: "deduct", label: Text("- Jarima"), icon: Icon(Icons.remove)),
                ],
                selected: {action},
                onSelectionChanged: (val) => setDialogState(() => action = val.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Ball miqdori (masalan: 10)"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: "Sabab / Izoh"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton(
              onPressed: () async {
                final pts = int.tryParse(pointsCtrl.text.trim()) ?? 0;
                if (pts > 0) {
                  await ApiService.adjustStudentPoints(studentId, pts, action, commentCtrl.text.trim());
                  if (mounted) Navigator.pop(ctx);
                  _loadStudents();
                }
              },
              child: const Text("Saqlash"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentDialog(int studentId, String studentName) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("To'lov Yozish ($studentName)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "To'lov Summasi (so'm)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Izoh (masalan: Sentyabr oyi uchun)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                final todayStr = DateTime.now().toIso8601String().split('T').first;
                final nextMonthStr = DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first;
                await ApiService.addPayment(studentId, amt, todayStr, nextMonthStr, noteCtrl.text.trim());
                if (mounted) Navigator.pop(ctx);
                _loadStudents();
              }
            },
            child: const Text("To'lovni Yozish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: "O'quvchini qidirish...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? const Center(child: Text("O'quvchilar topilmadi."))
                    : ListView.builder(
                        itemCount: _filteredStudents.length,
                        itemBuilder: (ctx, idx) {
                          final st = _filteredStudents[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.shade100,
                                child: const Icon(Icons.star, color: Colors.amber),
                              ),
                              title: Text(st["full_name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "Ball: ${st["total_points"]} ⭐\nOta-onasi: ${st["parent_name"] ?? "—"} (ID: ${st["parent_telegram_id"] ?? "—"})",
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == "points") {
                                    _showAdjustPointsDialog(st["id"], st["full_name"]);
                                  } else if (val == "payment") {
                                    _showAddPaymentDialog(st["id"], st["full_name"]);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: "points",
                                    child: Row(children: [Icon(Icons.star, color: Colors.amber), SizedBox(width: 8), Text("Ball kiritish")]),
                                  ),
                                  const PopupMenuItem(
                                    value: "payment",
                                    child: Row(children: [Icon(Icons.payment, color: Colors.green), SizedBox(width: 8), Text("To'lov yozish")]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Yangi O'quvchi"),
      ),
    );
  }
}
