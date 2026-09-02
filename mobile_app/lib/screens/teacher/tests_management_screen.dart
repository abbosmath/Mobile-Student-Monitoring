import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TestsManagementScreen extends StatefulWidget {
  const TestsManagementScreen({super.key});

  @override
  State<TestsManagementScreen> createState() => _TestsManagementScreenState();
}

class _TestsManagementScreenState extends State<TestsManagementScreen> {
  List<dynamic> _tests = [];
  List<dynamic> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tests = await ApiService.getTeacherTests();
    final groups = await ApiService.getTeacherGroups();
    setState(() {
      _tests = tests;
      _groups = groups;
      _isLoading = false;
    });
  }

  void _showCreateTestDialog() {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Avval guruh yarating!")),
      );
      return;
    }

    int selectedGroupId = _groups.first["id"];
    final titleCtrl = TextEditingController();
    final timeLimitCtrl = TextEditingController(text: "15");

    // Dynamic questions list
    final List<Map<String, dynamic>> questions = [
      {
        "question_text": TextEditingController(),
        "optA": TextEditingController(),
        "optB": TextEditingController(),
        "optC": TextEditingController(),
        "optD": TextEditingController(),
        "correct": "A",
      }
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yangi Test Yaratish"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: selectedGroupId,
                  isExpanded: true,
                  items: _groups.map<DropdownMenuItem<int>>((g) {
                    return DropdownMenuItem<int>(
                      value: g["id"],
                      child: Text(g["name"]),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedGroupId = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Test Mavzusi / Nomi"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: timeLimitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Vaqt cheklovi (daqiqa)"),
                ),
                const Divider(height: 24),
                const Text("Savollar:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Savol #${idx + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextField(controller: q["question_text"], decoration: const InputDecoration(labelText: "Savol matni")),
                          TextField(controller: q["optA"], decoration: const InputDecoration(labelText: "A javob")),
                          TextField(controller: q["optB"], decoration: const InputDecoration(labelText: "B javob")),
                          TextField(controller: q["optC"], decoration: const InputDecoration(labelText: "C javob")),
                          TextField(controller: q["optD"], decoration: const InputDecoration(labelText: "D javob")),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text("To'g'ri variant: "),
                              DropdownButton<String>(
                                value: q["correct"],
                                items: ["A", "B", "C", "D"].map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => q["correct"] = val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                ElevatedButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      questions.add({
                        "question_text": TextEditingController(),
                        "optA": TextEditingController(),
                        "optB": TextEditingController(),
                        "optC": TextEditingController(),
                        "optD": TextEditingController(),
                        "correct": "A",
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Yana Savol Qo'shish"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
            ElevatedButton(
              onPressed: () async {
                final timeLimit = int.tryParse(timeLimitCtrl.text.trim()) ?? 0;
                final List<Map<String, dynamic>> payloadQuestions = [];

                for (var q in questions) {
                  final text = (q["question_text"] as TextEditingController).text.trim();
                  if (text.isEmpty) continue;
                  final optA = (q["optA"] as TextEditingController).text.trim();
                  final optB = (q["optB"] as TextEditingController).text.trim();
                  final optC = (q["optC"] as TextEditingController).text.trim();
                  final optD = (q["optD"] as TextEditingController).text.trim();
                  final correct = q["correct"];

                  payloadQuestions.add({
                    "question_text": text,
                    "points": 1,
                    "options": [
                      {"option_text": optA, "is_correct": correct == "A"},
                      {"option_text": optB, "is_correct": correct == "B"},
                      {"option_text": optC, "is_correct": correct == "C"},
                      {"option_text": optD, "is_correct": correct == "D"},
                    ],
                  });
                }

                if (titleCtrl.text.trim().isNotEmpty && payloadQuestions.isNotEmpty) {
                  await ApiService.createTest(selectedGroupId, titleCtrl.text.trim(), null, timeLimit, payloadQuestions);
                  if (mounted) Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text("Testni Yaratish"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tests.isEmpty
              ? const Center(child: Text("Hali testlar yaratilmagan."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tests.length,
                  itemBuilder: (ctx, idx) {
                    final t = _tests[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          child: Icon(Icons.assignment, color: Colors.indigo.shade900),
                        ),
                        title: Text(t["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Guruh: ${t["group_name"]} | Savollar: ${t["question_count"]} ta | Vaqt: ${t["time_limit_minutes"]} daq"),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTestDialog,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text("Yangi Test"),
      ),
    );
  }
}
