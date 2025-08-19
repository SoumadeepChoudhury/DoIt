import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;
  static final AppDatabase instance = AppDatabase._constructor();

  // table and column names
  final String tableName = "tasks";
  final String columnId = "id";
  final String columnTitle = "title";
  final String columnDescription = "description";
  final String columnIsDone = "isDone";
  final String columnRepeat = "repeat";
  final String columnDate = "date";
  final String columnTime = "time";

  AppDatabase._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "doit.db");

    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnTitle TEXT,
            $columnDescription TEXT,
            $columnIsDone INTEGER,
            $columnRepeat TEXT,
            $columnDate TEXT,
            $columnTime TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE history (
            day TEXT PRIMARY KEY
          )
        ''');
      },
    );
    return database;
  }

  // Add New task
  Future<int> addTask(String title, String description, int isDone,
      String repeat, String date, String time) async {
    final db = await database;
    final id = await db.insert(tableName, {
      columnTitle: title,
      columnDescription: description,
      columnIsDone: isDone,
      columnRepeat: repeat,
      columnDate: date,
      columnTime: time
    });
    return id;
  }

  // Update Task
  void updateTask(int id, String title, String description, int isDone,
      String repeat, String date, String time) async {
    final db = await database;
    await db.update(
        tableName,
        {
          columnTitle: title,
          columnDescription: description,
          columnIsDone: isDone,
          columnRepeat: repeat,
          columnDate: date,
          columnTime: time
        },
        where: '$columnId = ?',
        whereArgs: [id]);
  }

  // Delete Task
  void deleteTask(int id) async {
    final db = await database;
    await db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }

  // Get All Tasks
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    return await db.query(tableName);
  }

  // Get total count of tasks
  Future<int> getTotalTasksCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get All History
  Future<List<String>> getAllHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query("history");
    return results.map((e) => e['day'] as String).toList();
  }

  // Add to History
  void addToHistory(String day) async {
    final db = await database;
    try {
      await db.insert("history", {"day": day});
    } catch (e) {}
  }

  //Remove from history
  Future<void> removeFromHistory(String day) async {
    final db = await database;
    try {
      await db.delete("history", where: "day = ?", whereArgs: [day]);
    } catch (e) {
      // Handle any errors that may occur during deletion
      print("Error removing from history: $e");
    }
  }
}
