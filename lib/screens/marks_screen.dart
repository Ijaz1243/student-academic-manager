import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/storage_service.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> courses = [];

  bool isLoading = true;

  int _selectedSemester = 0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // ================= LOAD COURSES =================

  Future<void> _loadCourses() async {
    setState(() {
      isLoading = true;
    });

    final data = await _storageService.getCourses();

    if (!mounted) return;

    setState(() {
      courses = data;
      isLoading = false;
    });
  }

  // ================= FILTERED COURSES =================

  List<Map<String, dynamic>> get filteredCourses {
    if (_selectedSemester == 0) {
      return courses;
    }

    return courses.where((course) {
      return course['semester'] == _selectedSemester;
    }).toList();
  }

  // ================= AVERAGE MARKS =================

  double get averageMarks {
    if (filteredCourses.isEmpty) return 0;

    double total = 0;

    for (final course in filteredCourses) {
      total += (course['marks'] ?? 0).toDouble();
    }

    return total / filteredCourses.length;
  }

  // ================= HIGHEST MARKS =================

  double get highestMarks {
    if (filteredCourses.isEmpty) return 0;

    double highest = 0;

    for (final course in filteredCourses) {
      final marks = (course['marks'] ?? 0).toDouble();

      if (marks > highest) {
        highest = marks;
      }
    }

    return highest;
  }

  // ================= LOWEST MARKS =================

  double get lowestMarks {
    if (filteredCourses.isEmpty) return 0;

    double lowest = (filteredCourses.first['marks'] ?? 0).toDouble();

    for (final course in filteredCourses) {
      final marks = (course['marks'] ?? 0).toDouble();

      if (marks < lowest) {
        lowest = marks;
      }
    }

    return lowest;
  }

  // ================= PASSED =================

  int get passedCourses {
    return filteredCourses.where((course) {
      final marks = (course['marks'] ?? 0).toDouble();

      return marks >= 50;
    }).length;
  }

  // ================= FAILED =================

  int get failedCourses {
    return filteredCourses.where((course) {
      final marks = (course['marks'] ?? 0).toDouble();

      return marks < 50;
    }).length;
  }

  // ================= GRADE =================

  String getGrade(double marks) {
    if (marks >= 85) return 'A';
    if (marks >= 80) return 'A-';
    if (marks >= 75) return 'B+';
    if (marks >= 70) return 'B';
    if (marks >= 65) return 'B-';
    if (marks >= 60) return 'C+';
    if (marks >= 55) return 'C';
    if (marks >= 50) return 'D';

    return 'F';
  }

  // ================= BAR CHART =================

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(filteredCourses.length, (index) {
      final course = filteredCourses[index];

      final double marks = (course['marks'] ?? 0).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: marks,
            width: 28,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  // ================= COURSE CODE =================

  String _courseCode(int index) {
    if (index < 0 || index >= filteredCourses.length) {
      return '';
    }

    return filteredCourses[index]['code']?.toString() ?? '';
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final displayedCourses = filteredCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks Analyzer'),

        actions: [
          IconButton(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourses,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ================= TITLE =================

                    const Text(
                      'Academic Performance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= SEMESTER FILTER =================
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: Row(
                        children: [
                          _semesterChip(label: 'All', value: 0),

                          const SizedBox(width: 8),

                          _semesterChip(label: 'Sem 1', value: 1),

                          const SizedBox(width: 8),

                          _semesterChip(label: 'Sem 2', value: 2),

                          const SizedBox(width: 8),

                          _semesterChip(label: 'Sem 3', value: 3),

                          const SizedBox(width: 8),

                          _semesterChip(label: 'Sem 4', value: 4),

                          const SizedBox(width: 8),

                          _semesterChip(label: 'Sem 5', value: 5),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================= NO COURSES =================
                    if (displayedCourses.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No courses available for this semester.\n\n'
                              'Add courses from My Courses.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // ================= STATISTICS =================

                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Average',
                              averageMarks.toStringAsFixed(1),
                              Icons.analytics,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _statCard(
                              'Highest',
                              highestMarks.toStringAsFixed(1),
                              Icons.trending_up,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Lowest',
                              lowestMarks.toStringAsFixed(1),
                              Icons.trending_down,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _statCard(
                              'Passed',
                              passedCourses.toString(),
                              Icons.check_circle,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Failed',
                              failedCourses.toString(),
                              Icons.cancel,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _statCard(
                              'Courses',
                              displayedCourses.length.toString(),
                              Icons.menu_book,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ================= CHART =================
                      const Text(
                        'Marks Visualization',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Course-wise marks performance',
                        style: TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),

                          child: SizedBox(
                            height: 300,

                            child: BarChart(
                              BarChartData(
                                minY: 0,
                                maxY: 100,

                                alignment: BarChartAlignment.spaceAround,

                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: 20,
                                ),

                                borderData: FlBorderData(show: false),

                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),

                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),

                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 35,
                                      interval: 20,
                                    ),
                                  ),

                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 45,

                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();

                                        if (index < 0 ||
                                            index >= filteredCourses.length) {
                                          return const SizedBox();
                                        }

                                        return SideTitleWidget(
                                          meta: meta,
                                          child: Text(
                                            _courseCode(index),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                barGroups: _buildBarGroups(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ================= COURSE PERFORMANCE =================
                      const Text(
                        'Course Performance',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

                        itemCount: displayedCourses.length,

                        itemBuilder: (context, index) {
                          final course = displayedCourses[index];

                          final double marks = (course['marks'] ?? 0)
                              .toDouble();

                          final String grade =
                              course['grade']?.toString() ?? getGrade(marks);

                          final bool isPassed = marks >= 50;

                          final String semester =
                              course['semester']?.toString() ?? '1';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),

                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPassed
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,

                                child: Icon(
                                  isPassed ? Icons.check : Icons.close,

                                  color: isPassed ? Colors.green : Colors.red,
                                ),
                              ),

                              title: Text(
                                course['name']?.toString() ?? 'Unknown Course',

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Text(
                                '${course['code']}\n'
                                'Semester: $semester\n'
                                'Marks: '
                                '${marks.toStringAsFixed(1)} / 100',
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

                                  const Text(
                                    'Grade',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ================= SEMESTER CHIP =================

  Widget _semesterChip({required String label, required int value}) {
    return ChoiceChip(
      label: Text(label),

      selected: _selectedSemester == value,

      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSemester = value;
          });
        }
      },
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
}
