import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Teacher Form Controls
  final _teacherUserCtrl = TextEditingController();
  final _teacherPassCtrl = TextEditingController();

  // Student Form Controls
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
      setState(() => _errorMessage = "Please enter username and password.");
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
      setState(() => _errorMessage = res["error"] ?? "Login failed. Check credentials.");
    }
  }

  void _loginStudent() async {
    final identifier = _studentIdCtrl.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = "Please enter Student ID, Phone, or Telegram ID.");
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
      setState(() => _errorMessage = res["error"] ?? "Student not found.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Student Monitoring",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Mobile Platform for Teachers & Students",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                // Card Container
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.indigo.shade900,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.indigo.shade900,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(icon: Icon(Icons.person_rounded), text: "O'qituvchi"),
                            Tab(icon: Icon(Icons.face_rounded), text: "O'quvchi / Ota-ona"),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        SizedBox(
                          height: 220,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Teacher Login Tab
                              Column(
                                children: [
                                  TextField(
                                    controller: _teacherUserCtrl,
                                    decoration: InputDecoration(
                                      labelText: "Foydalanuvchi nomi",
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _teacherPassCtrl,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: "Parol",
                                      prefixIcon: const Icon(Icons.lock),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _loginTeacher,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade900,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text("Kirish", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),

                              // Student Login Tab
                              Column(
                                children: [
                                  TextField(
                                    controller: _studentIdCtrl,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      labelText: "ID, Telefon yoki Telegram ID",
                                      hintText: "Masalan: 101, +99890... yoki 12345678",
                                      prefixIcon: const Icon(Icons.badge),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "📌 Telegram ID yoki Telefon raqamingiz orqali tizimga tezkor kiring.",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _loginStudent,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade900,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text("Kirish", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
