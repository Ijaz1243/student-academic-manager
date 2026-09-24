import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'academic_history_screen.dart';

class CgpaScreen extends StatefulWidget {
  const CgpaScreen({super.key});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen> {
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> courses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final data = await _storageService.getCourses();

    if (!mounted) return;

    setState(() {
      courses = data;
      isLoading = false;
    });
  }

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

  double get totalCredits {
    double total = 0;

    for (final course in courses) {
      total += (course['credits'] ?? 0).toDouble();
    }

    return total;
  }

  double get gpa {
    if (courses.isEmpty || totalCredits == 0) {
      return 0;
    }

    double totalGradePoints = 0;

    for (final course in courses) {
      final double credits = (course['credits'] ?? 0).toDouble();

      final String grade = course['grade'] ?? 'F';

      totalGradePoints += credits * gradePoint(grade);
    }

    return totalGradePoints / totalCredits;
  }

  void _openAcademicHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AcademicHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _openAcademicHistory,
            icon: const Icon(Icons.history),
            tooltip: 'Academic History',
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
          ? const Center(
              child: Text(
                'No courses available.\nAdd courses from My Courses.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCourses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // CURRENT GPA CARD
                    // =========================
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Current GPA',
                              style: TextStyle(fontSize: 18),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              gpa.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Total Credit Hours: '
                              '${totalCredits.toInt()}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // ACADEMIC HISTORY BUTTON
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openAcademicHistory,
                        icon: const Icon(Icons.history),
                        label: const Text('View Academic History'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // COURSE GRADES
                    // =========================
                    const Text(
                      'Course Grades',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        final String grade = course['grade'] ?? 'F';

                        final double credits = (course['credits'] ?? 0)
                            .toDouble();

                        final double marks = (course['marks'] ?? 0).toDouble();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.school),
                            ),

                            title: Text(
                              course['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              '${course['code']}\n'
                              'Credits: ${credits.toInt()} | '
                              'Marks: ${marks.toStringAsFixed(1)}',
                            ),

                            isThreeLine: true,

                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  grade,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  gradePoint(grade).toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
