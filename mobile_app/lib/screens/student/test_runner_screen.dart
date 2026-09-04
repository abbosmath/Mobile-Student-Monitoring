import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/primary_button.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            children: [
              Text("🎉", style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text("Test Yakunlandi!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${result["score"]} / ${result["total_questions"]}",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              const Text("To'g me'yoriy javoblar", style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "+${result["score"]} Ball qo'shildi ⭐",
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            PrimaryButton(
              text: "Tugatish va Qaytish",
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
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
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          widget.testData["title"],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_remainingSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppTheme.danger, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimer(_remainingSeconds),
                        style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / questions.length,
                minHeight: 8,
                backgroundColor: AppTheme.border,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Savol ${_currentIndex + 1} / ${questions.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${currentQuestion["points"] ?? 1} ball",
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Card
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentQuestion["image_url"] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        currentQuestion["image_url"],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    currentQuestion["question_text"],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark, height: 1.4),
                  ),
                ],
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

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ModernCard(
                      onTap: () {
                        setState(() {
                          _selectedAnswers[questionId] = opt["id"];
                        });
                      },
                      color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.bgLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              opt["option_text"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppTheme.primary : AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation Controls
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Oldingi", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: _currentIndex < questions.length - 1
                      ? PrimaryButton(
                          text: "Keyingi",
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => setState(() => _currentIndex++),
                        )
                      : PrimaryButton(
                          text: "Yakunlash",
                          icon: Icons.check_circle_rounded,
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                          isLoading: _isSubmitting,
                          onPressed: _submitTest,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
