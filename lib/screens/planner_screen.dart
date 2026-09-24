import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= LOAD TASKS =================

  Future<void> _loadTasks() async {
    final data = await _storageService.getTasks();

    if (!mounted) return;

    setState(() {
      tasks = data;
      isLoading = false;
    });
  }

  // ================= DATE FORMAT =================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$year-$month-$day';
  }

  // ================= PARSE DATE =================

  DateTime? _parseDate(String dateText) {
    // New format: 2026-09-30
    final parsed = DateTime.tryParse(dateText);

    if (parsed != null) {
      return parsed;
    }

    // Support old format such as:
    // 30 Sep 2026
    final parts = dateText.trim().split(' ');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);

      final months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };

      final month = months[parts[1]];

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  // ================= OVERDUE =================

  bool _isOverdue(Map<String, dynamic> task) {
    if (task['completed'] == 1) {
      return false;
    }

    final dueDate = _parseDate(task['dueDate'].toString());

    if (dueDate == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    return dueDate.isBefore(today);
  }

  // ================= FILTERED TASKS =================

  List<Map<String, dynamic>> get filteredTasks {
    final searchText = _searchController.text.trim().toLowerCase();

    return tasks.where((task) {
      final title = task['title'].toString().toLowerCase();

      final type = task['type'].toString().toLowerCase();

      final completed = task['completed'] == 1;

      final overdue = _isOverdue(task);

      final matchesSearch =
          searchText.isEmpty ||
          title.contains(searchText) ||
          type.contains(searchText);

      bool matchesFilter = true;

      if (selectedFilter == 'Pending') {
        matchesFilter = !completed;
      } else if (selectedFilter == 'Completed') {
        matchesFilter = completed;
      } else if (selectedFilter == 'Overdue') {
        matchesFilter = overdue;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ================= ADD TASK =================

  void _addTask() {
    final titleController = TextEditingController();

    final typeController = TextEditingController();

    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Task'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'Example: Database Assignment',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Task Type',
                        hintText: 'Example: Assignment',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          selectedDate == null
                              ? 'Select Due Date'
                              : 'Due Date: '
                                    '${_formatDate(selectedDate!)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        typeController.text.isNotEmpty &&
                        selectedDate != null) {
                      await _storageService.addTask({
                        'title': titleController.text.trim(),
                        'type': typeController.text.trim(),
                        'dueDate': _formatDate(selectedDate!),
                        'completed': 0,
                      });

                      if (!context.mounted) return;

                      Navigator.pop(context);

                      await _loadTasks();
                    }
                  },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= COMPLETE TASK =================

  Future<void> _toggleTask(Map<String, dynamic> task, bool value) async {
    await _storageService.updateTask(task['id'], {
      'title': task['title'],
      'type': task['type'],
      'dueDate': task['dueDate'],
      'completed': value ? 1 : 0,
    });

    await _loadTasks();
  }

  // ================= DELETE TASK =================

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    await _storageService.deleteTask(task['id']);

    await _loadTasks();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Planner'),
        actions: [
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
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
                      hintText: 'Search tasks...',
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
                              child: Text('All Tasks'),
                            ),
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed'),
                            ),
                            DropdownMenuItem(
                              value: 'Overdue',
                              child: Text('Overdue'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              selectedFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= TASK LIST =================
                Expanded(
                  child: visibleTasks.isEmpty
                      ? Center(
                          child: Text(
                            tasks.isEmpty
                                ? 'No tasks added yet.'
                                : 'No tasks found.',
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: visibleTasks.length,
                          itemBuilder: (context, index) {
                            final task = visibleTasks[index];

                            final bool completed = task['completed'] == 1;

                            final bool overdue = _isOverdue(task);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),

                              child: ListTile(
                                leading: Checkbox(
                                  value: completed,
                                  onChanged: (value) {
                                    if (value != null) {
                                      _toggleTask(task, value);
                                    }
                                  },
                                ),

                                title: Text(
                                  task['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),

                                    Text(task['type']),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Due: '
                                      '${task['dueDate']}',
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: [
                                        Icon(
                                          completed
                                              ? Icons.check_circle
                                              : overdue
                                              ? Icons.warning
                                              : Icons.schedule,
                                          size: 16,
                                          color: completed
                                              ? Colors.green
                                              : overdue
                                              ? Colors.red
                                              : Colors.orange,
                                        ),

                                        const SizedBox(width: 5),

                                        Text(
                                          completed
                                              ? 'Completed'
                                              : overdue
                                              ? 'Overdue'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: completed
                                                ? Colors.green
                                                : overdue
                                                ? Colors.red
                                                : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                isThreeLine: true,

                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteTask(task);
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
}
