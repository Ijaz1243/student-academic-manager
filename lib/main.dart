import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

void main() {
  runApp(const StudentAcademicManager());
}

class StudentAcademicManager extends StatefulWidget {
  const StudentAcademicManager({super.key});

  @override
  State<StudentAcademicManager> createState() => _StudentAcademicManagerState();
}

class _StudentAcademicManagerState extends State<StudentAcademicManager> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Student Academic Manager',

      themeMode: themeMode,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      home: DashboardScreen(
        onThemeToggle: toggleTheme,
        isDarkMode: themeMode == ThemeMode.dark,
      ),
    );
  }
}
