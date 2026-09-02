import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yangi Guruh Yaratish"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Guruh Nomi (masalan: Math 101)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: "Fan Nomi (masalan: Matematika)"),
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
              if (nameCtrl.text.trim().isNotEmpty) {
                await ApiService.createGroup(nameCtrl.text.trim(), subjectCtrl.text.trim(), []);
                if (mounted) Navigator.pop(ctx);
                _loadGroups();
              }
            },
            child: const Text("Yaratish"),
          ),
        ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text("${students.length} ta o'quvchi"),
                  backgroundColor: Colors.indigo.shade50,
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              "Guruhdagi O'quvchilar:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Hali o'quvchilar qo'shilmagan.", style: TextStyle(color: Colors.grey)),
              )
            else
              ...students.map((st) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(st["full_name"][0].toUpperCase()),
                    ),
                    title: Text(st["full_name"]),
                    subtitle: Text("Ball: ${st["total_points"]} ⭐ | Ota-onasi: ${st["parent_name"] ?? "Ko'rsatilmagan"}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () async {
                        await ApiService.removeStudentFromGroup(groupId, st["id"]);
                        if (mounted) Navigator.pop(ctx);
                        _openGroupDetails(groupId, groupName);
                      },
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Text("Hali birorta guruh yo'q. '+' tugmasi orqali yangi guruh yarating."),
                )
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (ctx, idx) {
                      final g = _groups[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.groups, color: Colors.indigo.shade900),
                          ),
                          title: Text(
                            g["name"],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text("Fan: ${g["subject"] ?? "Umumiy"} | O'quvchilar: ${g["student_count"]} ta"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _openGroupDetails(g["id"], g["name"]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Yangi Guruh"),
      ),
    );
  }
}
