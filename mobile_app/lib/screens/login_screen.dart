import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _teacherUserCtrl = TextEditingController();
  final _teacherPassCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teacherUserCtrl.dispose();
    _teacherPassCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  void _loginTeacher() async {
    final username = _teacherUserCtrl.text.trim();
    final password = _teacherPassCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Foydalanuvchi nomi va parolni kiriting.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.loginTeacher(username, password);

    setState(() => _isLoading = false);

    if (res.containsKey("token")) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
      );
    } else {
      setState(() => _errorMessage = res["error"] ?? "Tizimga kirishda xatolik.");
    }
  }

  void _loginStudent() async {
    final identifier = _studentIdCtrl.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = "ID, Telefon yoki Telegram ID kiriting.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.loginStudent(identifier);

    setState(() => _isLoading = false);

    if (res.containsKey("token")) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
      );
    } else {
      setState(() => _errorMessage = res["error"] ?? "O'quvchi topilmadi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.heroGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern Floating Logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Student Monitoring",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Ta'lim platformasiga xush kelibsiz",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Glassmorphic Auth Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab Selector
                        Container(
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: AppTheme.primary,
                            unselectedLabelColor: AppTheme.textMuted,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            tabs: const [
                              Tab(text: "O'qituvchi"),
                              Tab(text: "O'quvchi"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        SizedBox(
                          height: 240,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Teacher Login Form
                              Column(
                                children: [
                                  TextField(
                                    controller: _teacherUserCtrl,
                                    decoration: const InputDecoration(
                                      labelText: "Foydalanuvchi nomi",
                                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _teacherPassCtrl,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: "Parol",
                                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  PrimaryButton(
                                    text: "Kirish",
                                    icon: Icons.login_rounded,
                                    isLoading: _isLoading,
                                    onPressed: _loginTeacher,
                                  ),
                                ],
                              ),

                              // Student Login Form
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _studentIdCtrl,
                                    decoration: const InputDecoration(
                                      labelText: "ID, Telefon yoki Telegram ID",
                                      hintText: "Masalan: 101 yoki 901234567",
                                      prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text(
                                      "💡 Telegram ID yoki telefon raqamingiz bilan kiring.",
                                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  PrimaryButton(
                                    text: "Tizimga Kirish",
                                    icon: Icons.arrow_forward_rounded,
                                    isLoading: _isLoading,
                                    onPressed: _loginStudent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
