import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'test_runner_screen.dart';

class TestsListScreen extends StatefulWidget {
  const TestsListScreen({super.key});

  @override
  State<TestsListScreen> createState() => _TestsListScreenState();
}

class _TestsListScreenState extends State<TestsListScreen> {
  List<dynamic> _tests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    final tests = await ApiService.getStudentTests();
    setState(() {
      _tests = tests;
      _isLoading = false;
    });
  }

  void _startTest(int testId, String title) async {
    final detail = await ApiService.getStudentTestDetail(testId);

    if (detail.containsKey("error")) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail["error"]), backgroundColor: Colors.red),
      );
      return;
    }

    if (detail["has_submitted"] == true) {
      final sub = detail["submission"];
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text("Siz ushbu testni topshirgansiz!\n\nNatijangiz: ${sub["score"]} / ${sub["total_questions"]} ball"),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Yopish"))],
        ),
      );
      return;
    }

    final testData = detail["test"];
    if (testData != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestRunnerScreen(testData: testData),
        ),
      ).then((_) => _loadTests());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tests.isEmpty
              ? const Center(child: Text("Hozircha guruh testlari mavjud emas."))
              : RefreshIndicator(
                  onRefresh: _loadTests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tests.length,
                    itemBuilder: (ctx, idx) {
                      final t = _tests[idx];
                      final hasSubmitted = t["has_submitted"] == true;
                      final sub = t["submission"];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t["title"],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(t["group_name"]),
                                    backgroundColor: Colors.indigo.shade50,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Savollar: ${t["question_count"]} ta | Vaqt: ${t["time_limit_minutes"]} daq"),
                              const SizedBox(height: 12),
                              if (hasSubmitted)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text("Topshirilgan: ${sub["score"]} / ${sub["total_questions"]} ball", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _startTest(t["id"], t["title"]),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade900,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text("Testni Boshlash"),
                                  ),
                                ),
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
