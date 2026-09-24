import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class StorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final dbPath = join(databasePath, 'student_academic_manager.db');

    return await openDatabase(
      dbPath,
      version: 4,

      // ================= CREATE DATABASE =================
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            credits INTEGER NOT NULL,
            instructor TEXT NOT NULL,
            marks REAL NOT NULL DEFAULT 0,
            grade TEXT NOT NULL DEFAULT 'F',
            semester INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            dueDate TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE semester_courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            semester INTEGER NOT NULL,
            courseName TEXT NOT NULL,
            creditHours INTEGER NOT NULL,
            grade TEXT NOT NULL,
            gradePoint REAL NOT NULL
          )
        ''');
      },

      // ================= DATABASE UPGRADE =================
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE courses ADD COLUMN marks REAL NOT NULL DEFAULT 0",
          );

          await db.execute(
            "ALTER TABLE courses ADD COLUMN grade TEXT NOT NULL DEFAULT 'F'",
          );
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE semester_courses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              semester INTEGER NOT NULL,
              courseName TEXT NOT NULL,
              creditHours INTEGER NOT NULL,
              grade TEXT NOT NULL,
              gradePoint REAL NOT NULL
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE courses ADD COLUMN semester INTEGER NOT NULL DEFAULT 1",
          );
        }
      },
    );
  }

  // =========================================================
  // COURSES
  // =========================================================

  Future<int> addCourse(Map<String, dynamic> course) async {
    final db = await database;

    return await db.insert('courses', course);
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final db = await database;

    return await db.query('courses', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getCoursesBySemester(int semester) async {
    final db = await database;

    return await db.query(
      'courses',
      where: 'semester = ?',
      whereArgs: [semester],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateCourse(int id, Map<String, dynamic> course) async {
    final db = await database;

    return await db.update('courses', course, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;

    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  // TASKS
  // =========================================================

  Future<int> addTask(Map<String, dynamic> task) async {
    final db = await database;

    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;

    return await db.query('tasks', orderBy: 'id DESC');
  }

  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await database;

    return await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;

    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  // SEMESTER ACADEMIC HISTORY
  // =========================================================

  Future<int> addSemesterCourse(Map<String, dynamic> data) async {
    final db = await database;

    return await db.insert('semester_courses', data);
  }

  Future<List<Map<String, dynamic>>> getSemesterCourses(int semester) async {
    final db = await database;

    return await db.query(
      'semester_courses',
      where: 'semester = ?',
      whereArgs: [semester],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllAcademicRecords() async {
    final db = await database;

    return await db.query('semester_courses', orderBy: 'semester ASC, id ASC');
  }

  Future<int> deleteSemesterCourse(int id) async {
    final db = await database;

    return await db.delete(
      'semester_courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
