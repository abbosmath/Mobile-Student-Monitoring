import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TestRunnerScreen extends StatefulWidget {
  final Map<String, dynamic> testData;

  const TestRunnerScreen({super.key, required this.testData});

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionId -> optionId
  bool _isSubmitting = false;

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    final timeLimit = widget.testData["time_limit_minutes"] ?? 0;
    if (timeLimit > 0) {
      _remainingSeconds = timeLimit * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        _submitTest();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _submitTest() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    final testId = widget.testData["id"];
    final res = await ApiService.submitTest(testId, _selectedAnswers.map((k, v) => MapEntry(k.toString(), v)));

    setState(() => _isSubmitting = false);

    final result = res["result"];
    if (result != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("🎉 Test Yakunlandi!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${result["score"]} / ${result["total_questions"]}",
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              const Text("To'g'ri javoblar soni"),
              const SizedBox(height: 12),
              Chip(
                label: Text("+${result["score"]} Ball qo'shildi ⭐"),
                backgroundColor: Colors.amber.shade100,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900, foregroundColor: Colors.white),
              child: const Text("Tugatish"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.testData["questions"] as List<dynamic>? ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.testData["title"])),
        body: const Center(child: Text("Testda savollar mavjud emas.")),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final questionId = currentQuestion["id"];
    final options = currentQuestion["options"] as List<dynamic>? ?? [];
    final selectedOptionId = _selectedAnswers[questionId];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testData["title"]),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          if (_remainingSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _formatTimer(_remainingSeconds),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / questions.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.indigo.shade900,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Savol ${_currentIndex + 1} / ${questions.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(label: Text("${currentQuestion["points"] ?? 1} ball")),
              ],
            ),
            const SizedBox(height: 16),

            // Question Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentQuestion["image_url"] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          currentQuestion["image_url"],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      currentQuestion["question_text"],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (ctx, idx) {
                  final opt = options[idx];
                  final isSelected = selectedOptionId == opt["id"];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isSelected ? Colors.indigo.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.indigo.shade900 : Colors.grey.shade200,
                        foregroundColor: isSelected ? Colors.white : Colors.black,
                        child: Text(String.fromCharCode(65 + idx)),
                      ),
                      title: Text(opt["option_text"], style: const TextStyle(fontSize: 16)),
                      onTap: () {
                        setState(() {
                          _selectedAnswers[questionId] = opt["id"];
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // Navigation Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentIndex--),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Oldingi"),
                  )
                else
                  const SizedBox(),
                if (_currentIndex < questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _currentIndex++),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900, foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Keyingi"),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTest,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                    icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check),
                    label: const Text("Testni Yakunlash"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
