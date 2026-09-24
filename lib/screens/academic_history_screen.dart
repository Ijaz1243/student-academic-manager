import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class AcademicHistoryScreen extends StatefulWidget {
  const AcademicHistoryScreen({super.key});

  @override
  State<AcademicHistoryScreen> createState() => _AcademicHistoryScreenState();
}

class _AcademicHistoryScreenState extends State<AcademicHistoryScreen> {
  final StorageService _storageService = StorageService();

  int _selectedSemester = 1;

  List<Map<String, dynamic>> _allCourses = [];

  bool _isLoading = true;

  final Map<String, double> _gradingScale = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D': 1.0,
    'F': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  // ================= LOAD COURSES =================

  Future<void> _loadAcademicData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _storageService.getCourses();

    if (!mounted) return;

    setState(() {
      _allCourses = data;
      _isLoading = false;
    });
  }

  // ================= GRADE POINT =================

  double _getGradePoint(String? grade) {
    if (grade == null || grade.isEmpty) {
      return 0.0;
    }

    return _gradingScale[grade] ?? 0.0;
  }

  // ================= SEMESTER GPA =================

  double _calculateSemesterGPA(int semester) {
    final semCourses = _allCourses
        .where((course) => course['semester'] == semester)
        .toList();

    if (semCourses.isEmpty) {
      return 0.0;
    }

    double totalPoints = 0.0;
    int totalCredits = 0;

    for (final course in semCourses) {
      final int credits = (course['credits'] as num).toInt();

      final String grade = course['grade']?.toString() ?? 'F';

      final double gradePoint = _getGradePoint(grade);

      totalPoints += gradePoint * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) {
      return 0.0;
    }

    return totalPoints / totalCredits;
  }

  // ================= OVERALL CGPA =================

  double _calculateOverallCGPA() {
    if (_allCourses.isEmpty) {
      return 0.0;
    }

    double totalPoints = 0.0;
    int totalCredits = 0;

    for (final course in _allCourses) {
      final int credits = (course['credits'] as num).toInt();

      final String grade = course['grade']?.toString() ?? 'F';

      final double gradePoint = _getGradePoint(grade);

      totalPoints += gradePoint * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) {
      return 0.0;
    }

    return totalPoints / totalCredits;
  }

  // ================= TOTAL CREDITS =================

  int _getTotalCreditHours() {
    int total = 0;

    for (final course in _allCourses) {
      total += (course['credits'] as num).toInt();
    }

    return total;
  }

  // ================= PASSED COUNT =================

  int _getPassedCount() {
    return _allCourses.where((course) {
      final grade = course['grade']?.toString() ?? 'F';
      return grade != 'F';
    }).length;
  }

  // ================= FAILED COUNT =================

  int _getFailedCount() {
    return _allCourses.where((course) {
      final grade = course['grade']?.toString() ?? 'F';
      return grade == 'F';
    }).length;
  }

  // ================= DELETE COURSE =================

  Future<void> _deleteCourse(int id) async {
    await _storageService.deleteCourse(id);

    await _loadAcademicData();
  }

  // ================= DELETE CONFIRMATION =================

  Future<void> _confirmDeleteCourse(int id, String courseName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete "$courseName"?\n\n'
            'This will also remove the course from My Courses.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteCourse(id);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final semCourses = _allCourses
        .where((course) => course['semester'] == _selectedSemester)
        .toList();

    final overallCGPA = _calculateOverallCGPA();

    final semesterGPA = _calculateSemesterGPA(_selectedSemester);

    return Scaffold(
      // ================= APP BAR =================

      appBar: AppBar(
        title: const Text('Academic History'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadAcademicData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      // ================= BODY =================
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ================= OVERALL CGPA CARD =================

                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Overall CGPA',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          overallCGPA.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: overallCGPA >= 3.0
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(
                              'Credits',
                              '${_getTotalCreditHours()}',
                              Icons.credit_score,
                            ),
                            _statItem(
                              'Passed',
                              '${_getPassedCount()}',
                              Icons.check_circle,
                            ),
                            _statItem(
                              'Failed',
                              '${_getFailedCount()}',
                              Icons.cancel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ================= SEMESTER CHIPS =================
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: List.generate(5, (index) {
                      final semester = index + 1;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Semester $semester'),
                          selected: _selectedSemester == semester,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSemester = semester;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),

                // ================= SEMESTER GPA =================
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Semester $_selectedSemester GPA',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        semesterGPA.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= INFO =================
                if (semCourses.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No courses found for this semester.\n\n'
                          'Go to My Courses and add courses '
                          'with this semester selected.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  // ================= COURSE LIST =================
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: semCourses.length,
                      itemBuilder: (context, index) {
                        final course = semCourses[index];

                        final int id = (course['id'] as num).toInt();

                        final String code = course['code']?.toString() ?? '';

                        final String courseName =
                            course['name']?.toString() ?? 'Unknown Course';

                        final String grade = course['grade']?.toString() ?? 'F';

                        final int credits = (course['credits'] as num).toInt();

                        final int marks =
                            (course['marks'] as num?)?.toInt() ?? 0;

                        final double gradePoint = _getGradePoint(grade);

                        final bool isFailed = grade == 'F';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: ListTile(
                            // ================= GRADE =================

                            leading: CircleAvatar(
                              backgroundColor: isFailed
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              child: Text(
                                grade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isFailed
                                      ? Colors.red
                                      : Colors.blue.shade900,
                                ),
                              ),
                            ),

                            // ================= COURSE =================
                            title: Text(
                              code.isEmpty ? courseName : '$code - $courseName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // ================= DETAILS =================
                            subtitle: Text(
                              'Marks: $marks\n'
                              'Credit Hours: $credits\n'
                              'Grade Point: '
                              '${gradePoint.toStringAsFixed(2)}',
                            ),

                            isThreeLine: true,

                            // ================= DELETE =================
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                _confirmDeleteCourse(id, courseName);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  // ================= STAT ITEM =================

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
