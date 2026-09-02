import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _groups = [];
  int? _selectedGroupId;
  List<dynamic> _students = [];
  Map<int, String> _statuses = {};
  Map<int, int> _points = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

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
      if (groups.isNotEmpty) {
        _selectedGroupId = groups.first["id"];
        _loadGroupStudents(_selectedGroupId!);
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadGroupStudents(int groupId) async {
    setState(() => _isLoading = true);
    final detail = await ApiService.getGroupDetail(groupId);
    final groupData = detail["group"];
    final students = groupData?["students"] as List<dynamic>? ?? [];

    final Map<int, String> initStatuses = {};
    final Map<int, int> initPoints = {};

    for (var st in students) {
      initStatuses[st["id"]] = "present";
      initPoints[st["id"]] = 0;
    }

    setState(() {
      _students = students;
      _statuses = initStatuses;
      _points = initPoints;
      _isLoading = false;
    });
  }

  void _submitAttendance() async {
    if (_selectedGroupId == null || _students.isEmpty) return;

    setState(() => _isSubmitting = true);

    final List<Map<String, dynamic>> records = [];
    for (var st in _students) {
      final stId = st["id"];
      records.add({
        "student_id": stId,
        "status": _statuses[stId] ?? "present",
        "points": _points[stId] ?? 0,
        "comment": "Davomat belgilandi",
      });
    }

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final res = await ApiService.takeAttendance(_selectedGroupId!, todayStr, records);

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? "Davomat muvaffaqiyatli saqlandi!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group Selector Dropdown
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedGroupId,
                          isExpanded: true,
                          hint: const Text("Guruhni tanlang"),
                          items: _groups.map<DropdownMenuItem<int>>((g) {
                            return DropdownMenuItem<int>(
                              value: g["id"],
                              child: Text("${g["name"]} (${g["subject"] ?? "Fan"})", style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedGroupId = val);
                              _loadGroupStudents(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Students Attendance List
                  Expanded(
                    child: _students.isEmpty
                        ? const Center(child: Text("Ushbu guruhda o'quvchilar yo'q."))
                        : ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (ctx, idx) {
                              final st = _students[idx];
                              final stId = st["id"];
                              final status = _statuses[stId] ?? "present";
                              final currentPts = _points[stId] ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            st["full_name"],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Chip(
                                            label: Text("$currentPts ball"),
                                            backgroundColor: currentPts >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Status Buttons
                                          Expanded(
                                            child: SegmentedButton<String>(
                                              segments: const [
                                                ButtonSegment(value: "present", label: Text("Keldi"), icon: Icon(Icons.check, size: 14)),
                                                ButtonSegment(value: "absent", label: Text("Kelmadi"), icon: Icon(Icons.close, size: 14)),
                                                ButtonSegment(value: "late", label: Text("Kechikti"), icon: Icon(Icons.access_time, size: 14)),
                                              ],
                                              selected: {status},
                                              onSelectionChanged: (Set<String> newSelection) {
                                                setState(() {
                                                  _statuses[stId] = newSelection.first;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _points[stId] = (_points[stId] ?? 0) - 1;
                                              });
                                            },
                                          ),
                                          Text("Ball: $currentPts", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle, color: Colors.green),
                                            onPressed: () {
                                              setState(() {
                                                _points[stId] = (_points[stId] ?? 0) + 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Submit Button
                  if (_students.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.save),
                        label: const Text("Davomatni Saqlash", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
