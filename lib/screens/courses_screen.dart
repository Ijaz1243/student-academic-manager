import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> courses = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= LOAD COURSES =================

  Future<void> _loadCourses() async {
    final data = await _storageService.getCourses();

    if (!mounted) return;

    setState(() {
      courses = data;
      isLoading = false;
    });
  }

  // ================= CALCULATE GRADE =================

  String _getGrade(double marks) {
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

  // ================= SEARCH + FILTER =================

  List<Map<String, dynamic>> get filteredCourses {
    final searchText = _searchController.text.trim().toLowerCase();

    return courses.where((course) {
      final code = course['code'].toString().toLowerCase();

      final name = course['name'].toString().toLowerCase();

      final instructor = course['instructor'].toString().toLowerCase();

      final double marks = (course['marks'] ?? 0).toDouble();

      final matchesSearch =
          searchText.isEmpty ||
          code.contains(searchText) ||
          name.contains(searchText) ||
          instructor.contains(searchText);

      bool matchesFilter = true;

      if (selectedFilter == 'Passed') {
        matchesFilter = marks >= 50;
      } else if (selectedFilter == 'Failed') {
        matchesFilter = marks < 50;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ================= ADD COURSE =================

  void _addCourse() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final creditsController = TextEditingController();
    final instructorController = TextEditingController();
    final marksController = TextEditingController();

    int selectedSemester = 1;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Course Code',
                        hintText: 'Example: CS-316',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                        hintText: 'Example: Web Engineering',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: creditsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Credit Hours',
                        hintText: 'Example: 3',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(5, (index) {
                        final semester = index + 1;

                        return DropdownMenuItem<int>(
                          value: semester,
                          child: Text('Semester $semester'),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedSemester = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(
                        labelText: 'Instructor',
                        hintText: 'Example: Ahmad Khan',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: marksController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Marks',
                        hintText: 'Example: 85',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final marks = double.tryParse(marksController.text);

                    final credits = int.tryParse(creditsController.text);

                    if (codeController.text.isNotEmpty &&
                        nameController.text.isNotEmpty &&
                        credits != null &&
                        credits > 0 &&
                        instructorController.text.isNotEmpty &&
                        marks != null &&
                        marks >= 0 &&
                        marks <= 100) {
                      final navigator = Navigator.of(dialogContext);

                      await _storageService.addCourse({
                        'code': codeController.text.trim(),
                        'name': nameController.text.trim(),
                        'credits': credits,
                        'instructor': instructorController.text.trim(),
                        'marks': marks,
                        'grade': _getGrade(marks),
                        'semester': selectedSemester,
                      });

                      if (!mounted) return;

                      navigator.pop();

                      await _loadCourses();
                    }
                  },
                  child: const Text('Add Course'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= EDIT COURSE =================

  void _editCourse(int index) {
    final course = filteredCourses[index];

    final codeController = TextEditingController(text: course['code']);

    final nameController = TextEditingController(text: course['name']);

    final creditsController = TextEditingController(
      text: course['credits'].toString(),
    );

    final instructorController = TextEditingController(
      text: course['instructor'],
    );

    final marksController = TextEditingController(
      text: (course['marks'] ?? 0).toString(),
    );

    int selectedSemester = (course['semester'] ?? 1) as int;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Course Code',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: creditsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Credit Hours',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(5, (index) {
                        final semester = index + 1;

                        return DropdownMenuItem<int>(
                          value: semester,
                          child: Text('Semester $semester'),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedSemester = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(
                        labelText: 'Instructor',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: marksController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Marks',
                        hintText: 'Example: 85',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final marks = double.tryParse(marksController.text);

                    final credits = int.tryParse(creditsController.text);

                    if (codeController.text.isNotEmpty &&
                        nameController.text.isNotEmpty &&
                        credits != null &&
                        credits > 0 &&
                        instructorController.text.isNotEmpty &&
                        marks != null &&
                        marks >= 0 &&
                        marks <= 100) {
                      final navigator = Navigator.of(dialogContext);

                      await _storageService.updateCourse(course['id'], {
                        'code': codeController.text.trim(),
                        'name': nameController.text.trim(),
                        'credits': credits,
                        'instructor': instructorController.text.trim(),
                        'marks': marks,
                        'grade': _getGrade(marks),
                        'semester': selectedSemester,
                      });

                      if (!mounted) return;

                      navigator.pop();

                      await _loadCourses();
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DELETE COURSE =================

  void _deleteCourse(int index) {
    final course = filteredCourses[index];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Course'),

          content: Text(
            'Are you sure you want to delete '
            '${course['name']}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);

                await _storageService.deleteCourse(course['id']);

                if (!mounted) return;

                navigator.pop();

                await _loadCourses();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final visibleCourses = filteredCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addCourse,
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ================= SEARCH =================

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search course, code or instructor',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                // ================= FILTER =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Filter:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedFilter,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Courses'),
                            ),
                            DropdownMenuItem(
                              value: 'Passed',
                              child: Text('Passed'),
                            ),
                            DropdownMenuItem(
                              value: 'Failed',
                              child: Text('Failed'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ================= COURSE LIST =================
                Expanded(
                  child: visibleCourses.isEmpty
                      ? Center(
                          child: Text(
                            courses.isEmpty
                                ? 'No courses added yet.'
                                : 'No courses found.',
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: visibleCourses.length,
                          itemBuilder: (context, index) {
                            final course = visibleCourses[index];

                            final double marks = (course['marks'] ?? 0)
                                .toDouble();

                            final String grade =
                                course['grade'] ?? _getGrade(marks);

                            final int semester = course['semester'] ?? 1;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.menu_book),
                                ),

                                title: Text(
                                  course['code'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text(
                                  '${course['name']}\n'
                                  'Semester: $semester | '
                                  'Credits: '
                                  '${course['credits']}\n'
                                  'Instructor: '
                                  '${course['instructor']}\n'
                                  'Marks: $marks / 100 | '
                                  'Grade: $grade',
                                ),

                                isThreeLine: true,

                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editCourse(index);
                                    } else if (value == 'delete') {
                                      _deleteCourse(index);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 10),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete),
                                          SizedBox(width: 10),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
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
}
