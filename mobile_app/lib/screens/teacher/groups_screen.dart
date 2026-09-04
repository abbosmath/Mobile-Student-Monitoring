import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/primary_button.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final groups = await ApiService.getTeacherGroups();
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Yangi Guruh Yaratish",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Guruh Nomi",
                hintText: "masalan: Matematika 101",
                prefixIcon: Icon(Icons.group_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(
                labelText: "Fan Nomi",
                hintText: "masalan: Matematika",
                prefixIcon: Icon(Icons.book_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Saqlash va Yaratish",
              icon: Icons.check_circle_outline_rounded,
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await ApiService.createGroup(nameCtrl.text.trim(), subjectCtrl.text.trim(), []);
                  if (mounted) Navigator.pop(ctx);
                  _loadGroups();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openGroupDetails(int groupId, String groupName) async {
    final data = await ApiService.getGroupDetail(groupId);
    final groupInfo = data["group"];
    if (groupInfo == null || !mounted) return;

    final students = groupInfo["students"] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    groupName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${students.length} ta o'quvchi",
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            const Text(
              "Guruh O'quvchilari:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text("Hali o'quvchilar qo'shilmagan", style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              )
            else
              ...students.map((st) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
                        child: Text(
                          st["full_name"][0].toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(st["full_name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("⭐ ${st["total_points"]} ball"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.danger),
                        onPressed: () async {
                          await ApiService.removeStudentFromGroup(groupId, st["id"]);
                          if (mounted) Navigator.pop(ctx);
                          _openGroupDetails(groupId, groupName);
                        },
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _groups.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          "Hali guruhlar yaratilmadi",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Yangi guruh yaratish uchun pastdagi '+' tugmasini bosing.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _groups.length,
                    itemBuilder: (ctx, idx) {
                      final g = _groups[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ModernCard(
                          onTap: () => _openGroupDetails(g["id"], g["name"]),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAlignment.start,
                                  children: [
                                    Text(
                                      g["name"],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Fan: ${g["subject"] ?? "Umumiy"} • ${g["student_count"]} o'quvchi",
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Yangi Guruh", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
