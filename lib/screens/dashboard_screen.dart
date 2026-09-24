import 'package:flutter/material.dart';

import '../services/storage_service.dart';

import 'courses_screen.dart';
import 'marks_screen.dart';
import 'cgpa_screen.dart';
import 'planner_screen.dart';
import 'academic_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> tasks = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ================= LOAD DASHBOARD DATA =================

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    final courseData = await _storageService.getCourses();
    final taskData = await _storageService.getTasks();

    if (!mounted) return;

    setState(() {
      courses = courseData;
      tasks = taskData;
      isLoading = false;
    });
  }

  // ================= TOTAL CREDITS =================

  double get totalCredits {
    double total = 0;

    for (final course in courses) {
      total += (course['credits'] ?? 0).toDouble();
    }

    return total;
  }

  // ================= GRADE POINT =================

  double gradePoint(String grade) {
    switch (grade) {
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // ================= OVERALL CGPA =================

  double get cgpa {
    if (courses.isEmpty || totalCredits == 0) {
      return 0;
    }

    double totalGradePoints = 0;

    for (final course in courses) {
      final double credits = (course['credits'] ?? 0).toDouble();

      final String grade = course['grade']?.toString() ?? 'F';

      totalGradePoints += credits * gradePoint(grade);
    }

    return totalGradePoints / totalCredits;
  }

  // ================= PASSED COURSES =================

  int get passedCourses {
    return courses.where((course) {
      final double marks = (course['marks'] ?? 0).toDouble();

      return marks >= 50;
    }).length;
  }

  // ================= FAILED COURSES =================

  int get failedCourses {
    return courses.where((course) {
      final double marks = (course['marks'] ?? 0).toDouble();

      return marks < 50;
    }).length;
  }

  // ================= PENDING TASKS =================

  int get pendingTasks {
    return tasks.where((task) {
      final value = task['isCompleted'];

      if (value is bool) {
        return !value;
      }

      if (value is int) {
        return value == 0;
      }

      return true;
    }).length;
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= APP BAR =================

      appBar: AppBar(
        title: const Text('Student Academic Manager'),
        centerTitle: true,

        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),

          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
        ],
      ),

      // ================= BODY =================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ================= STUDENT PROFILE =================

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              child: Icon(Icons.person, size: 40),
                            ),

                            const SizedBox(width: 16),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Muhammad Ijaz Khan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 5),

                                  Text('Roll No: 24PWBCS1382'),

                                  Text('Semester: 5'),

                                  Text('Computer Science'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ================= ACADEMIC OVERVIEW =================
                    const Text(
                      'Academic Overview',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Row 1
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'CGPA',
                            cgpa.toStringAsFixed(2),
                            Icons.school,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            'Courses',
                            courses.length.toString(),
                            Icons.menu_book,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row 2
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Credits',
                            totalCredits.toStringAsFixed(0),
                            Icons.credit_score,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            'Pending',
                            pendingTasks.toString(),
                            Icons.pending_actions,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row 3
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Passed',
                            passedCourses.toString(),
                            Icons.check_circle,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            'Failed',
                            failedCourses.toString(),
                            Icons.cancel,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ================= QUICK ACTIONS =================
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= MY COURSES =================
                    _actionTile(
                      icon: Icons.menu_book,
                      title: 'My Courses',
                      subtitle: 'Manage your university courses',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoursesScreen(),
                          ),
                        );

                        await _loadDashboardData();
                      },
                    ),

                    // ================= MARKS ANALYZER =================
                    _actionTile(
                      icon: Icons.analytics,
                      title: 'Marks Analyzer',
                      subtitle: 'Analyze your academic performance',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MarksScreen(),
                          ),
                        );

                        await _loadDashboardData();
                      },
                    ),

                    // ================= CGPA CALCULATOR =================
                    _actionTile(
                      icon: Icons.calculate,
                      title: 'CGPA Calculator',
                      subtitle: 'Calculate GPA and CGPA',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CgpaScreen(),
                          ),
                        );

                        await _loadDashboardData();
                      },
                    ),

                    // ================= ACADEMIC HISTORY =================
                    _actionTile(
                      icon: Icons.history_edu,
                      title: 'Academic History',
                      subtitle: 'View semester GPA and overall CGPA',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AcademicHistoryScreen(),
                          ),
                        );

                        await _loadDashboardData();
                      },
                    ),

                    // ================= SEMESTER PLANNER =================
                    _actionTile(
                      icon: Icons.calendar_month,
                      title: 'Semester Planner',
                      subtitle: 'Manage your semester tasks',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlannerScreen(),
                          ),
                        );

                        await _loadDashboardData();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= STAT CARD =================

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Icon(icon, size: 30),

            const SizedBox(height: 8),

            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(title),
          ],
        ),
      ),
    );
  }

  // ================= ACTION TILE =================

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),

      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(subtitle),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: onTap,
      ),
    );
  }
}
