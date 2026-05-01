import 'package:intl/intl.dart';
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
  final String everydayReportsTable = "everyday_reports";
  final String everydayReportMonthsTable = "everyday_report_months";
  final String columnStartDate = "startDate";
  final String columnTotalCount = "totalCount";
  final String columnCompletedCount = "completedCount";
  final String columnMonth = "month";

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
      version: 5,
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

        await db.execute('''
          CREATE TABLE completed (
            id INTEGER PRIMARY KEY,
            count INTEGER DEFAULT 0
          )
        ''');
        await db.insert('completed', {'id': 1, 'count': 0});
        await _createEverydayReportsTable(db);
        await _createEverydayReportMonthsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'CREATE TABLE IF NOT EXISTS completed (id INTEGER PRIMARY KEY,count INTEGER DEFAULT 0)');
          await db.insert('completed', {'id': 1, 'count': 0},
              conflictAlgorithm: ConflictAlgorithm.ignore);
          print("Database upgraded to version 2: added 'completed' table.");
        }
        if (oldVersion < 3) {
          await _createEverydayReportsTable(db);
          print(
              "Database upgraded to version 3: added 'everyday_reports' table.");
        }
        if (oldVersion < 4) {
          await _createEverydayReportMonthsTable(db);
          await _syncEverydayReportsFromTasks(db);
          print(
              "Database upgraded to version 4: added 'everyday_report_months' table.");
        }
        if (oldVersion < 5) {
          await _syncEverydayReportsFromTasks(db);
          await _repairCompletedCountFromReports(db);
          print(
              "Database upgraded to version 5: repaired completed count from existing reports once.");
        }
      },
    );
    return database;
  }

  Future<void> _createEverydayReportsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $everydayReportsTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDescription TEXT NOT NULL DEFAULT '',
        $columnStartDate TEXT NOT NULL,
        $columnTotalCount INTEGER DEFAULT 0,
        $columnCompletedCount INTEGER DEFAULT 0,
        UNIQUE($columnTitle, $columnDescription)
      )
    ''');
  }

  Future<void> _createEverydayReportMonthsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $everydayReportMonthsTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDescription TEXT NOT NULL DEFAULT '',
        $columnMonth TEXT NOT NULL,
        $columnCompletedCount INTEGER DEFAULT 0,
        UNIQUE($columnTitle, $columnDescription, $columnMonth)
      )
    ''');
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
  Future<void> updateTask(int id, String title, String description, int isDone,
      String repeat, String date, String time) async {
    final db = await database;
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();

    await db.transaction((txn) async {
      final oldRows = await txn.query(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
        limit: 1,
      );
      final oldTask = oldRows.isEmpty ? null : oldRows.first;
      final oldTitle = (oldTask?[columnTitle] ?? '').toString().trim();
      final oldDescription =
          (oldTask?[columnDescription] ?? '').toString().trim();
      final oldRepeat = (oldTask?[columnRepeat] ?? '').toString();

      await txn.update(
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

      final reportKeyChanged = oldTitle != normalizedTitle ||
          oldDescription != normalizedDescription;
      if (reportKeyChanged &&
          (oldRepeat == "Everyday" || repeat == "Everyday")) {
        await _renameEverydayReport(
          txn,
          oldTitle,
          oldDescription,
          normalizedTitle,
          normalizedDescription,
        );
      }
    });
  }

  // Delete Task
  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
    await syncEverydayReportsFromTasks();
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

  Future<int> getCompletedTasksCount() async {
    final db = await database;

    final result = await db.rawQuery('SELECT count FROM completed where id=1');
    final completedTableCount = Sqflite.firstIntValue(result) ?? 0;
    final taskResult = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableName WHERE $columnIsDone = 1',
    );
    final completedTaskRowsCount = Sqflite.firstIntValue(taskResult) ?? 0;

    final repairedCount = _maxInt(completedTableCount, completedTaskRowsCount);

    if (repairedCount > completedTableCount) {
      await db.insert(
        'completed',
        {'id': 1, 'count': repairedCount},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return repairedCount;
  }

  Future<void> _repairCompletedCountFromReports(DatabaseExecutor db) async {
    final completedResult =
        await db.rawQuery('SELECT count FROM completed where id=1');
    final completedTableCount = Sqflite.firstIntValue(completedResult) ?? 0;
    final taskResult = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableName WHERE $columnIsDone = 1',
    );
    final completedTaskRowsCount = Sqflite.firstIntValue(taskResult) ?? 0;
    final reportResult = await db.rawQuery(
      'SELECT COALESCE(SUM($columnCompletedCount), 0) '
      'FROM $everydayReportMonthsTable',
    );
    final everydayReportCompletedCount =
        Sqflite.firstIntValue(reportResult) ?? 0;
    final repairedCount = _maxInt(
      completedTableCount,
      _maxInt(completedTaskRowsCount, everydayReportCompletedCount),
    );

    if (repairedCount > completedTableCount) {
      await db.insert(
        'completed',
        {'id': 1, 'count': repairedCount},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
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

  Future<void> incrementCompletedCount() async {
    final db = await database;

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> result = await txn.query('completed');

      if (result.isNotEmpty) {
        int currentCount = result.first['count'] as int;
        print("Current completed count: $currentCount");

        await txn.update(
          'completed',
          {'count': currentCount + 1},
          where: 'id = ?',
          whereArgs: [1],
        );
      } else {
        // Fallback: If table is somehow empty, insert the first record
        await txn.insert('completed', {'count': 1});
      }
    });
  }

  Future<void> decrementCompletedCount() async {
    final db = await database;

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> result = await txn.query('completed');

      if (result.isNotEmpty) {
        int currentCount = result.first['count'] as int;
        print("Current completed count before decrement: $currentCount");

        // Ensure count doesn't go below 0
        if (currentCount > 0) {
          await txn.update(
            'completed',
            {'count': currentCount - 1},
            where: 'id = ?',
            whereArgs: [1],
          );
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getEverydayReports() async {
    final db = await database;
    await syncEverydayReportsFromTasks();
    return await db.query(everydayReportsTable);
  }

  Future<List<String>> getAvailableEverydayReportMonths() async {
    final db = await database;
    await syncEverydayReportsFromTasks();

    final dateCandidates = <DateTime>[];
    final tasks = await db.query(tableName, columns: [columnDate]);
    for (final task in tasks) {
      final taskDate = _tryParseTaskDate((task[columnDate] ?? '').toString());
      if (taskDate != null) dateCandidates.add(taskDate);
    }

    final reports =
        await db.query(everydayReportsTable, columns: [columnStartDate]);
    for (final report in reports) {
      final startDate =
          _tryParseTaskDate((report[columnStartDate] ?? '').toString());
      if (startDate != null) dateCandidates.add(startDate);
    }

    final storedMonths =
        await db.query(everydayReportMonthsTable, columns: [columnMonth]);
    for (final month in storedMonths) {
      final monthDate = _tryParseMonth((month[columnMonth] ?? '').toString());
      if (monthDate != null) dateCandidates.add(monthDate);
    }

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final installMonth = dateCandidates.isEmpty
        ? currentMonth
        : _monthOnly(dateCandidates.reduce((a, b) => a.isBefore(b) ? a : b));
    final sixMonthWindowStart = _addMonths(currentMonth, -5);
    final firstVisibleMonth = installMonth.isAfter(sixMonthWindowStart)
        ? installMonth
        : sixMonthWindowStart;

    final months = <String>[];
    DateTime cursor = currentMonth;
    while (!cursor.isBefore(firstVisibleMonth)) {
      months.add(DateFormat('yyyy-M').format(cursor));
      cursor = _addMonths(cursor, -1);
    }
    return months;
  }

  Future<List<Map<String, dynamic>>> getEverydayReportsForMonth(
      String month) async {
    final db = await database;
    await syncEverydayReportsFromTasks();
    final selectedMonth = _tryParseMonth(month) ?? DateTime.now();
    final daysInMonth = _daysInMonth(selectedMonth);
    final rows = await db.query(
      everydayReportMonthsTable,
      where: '$columnMonth = ?',
      whereArgs: [month],
    );

    return rows.map((row) {
      return {
        columnTitle: row[columnTitle],
        columnDescription: row[columnDescription],
        columnStartDate: DateFormat('yyyy-M-d')
            .format(DateTime(selectedMonth.year, selectedMonth.month, 1)),
        columnTotalCount: daysInMonth,
        columnCompletedCount: row[columnCompletedCount],
      };
    }).toList();
  }

  Future<void> syncEverydayReportsFromTasks() async {
    final db = await database;
    await db.transaction((txn) async {
      await _syncEverydayReportsFromTasks(txn);
    });
  }

  Future<void> incrementEverydayReportCompletedCount(
      String title, String description,
      [String? date]) async {
    await _changeEverydayReportCompletedCount(title, description, 1, date);
  }

  Future<void> decrementEverydayReportCompletedCount(
      String title, String description,
      [String? date]) async {
    await _changeEverydayReportCompletedCount(title, description, -1, date);
  }

  Future<void> _changeEverydayReportCompletedCount(
      String title, String description, int delta, String? date) async {
    final db = await database;
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    await db.transaction((txn) async {
      var rows = await txn.query(
        everydayReportsTable,
        columns: [columnCompletedCount],
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [normalizedTitle, normalizedDescription],
        limit: 1,
      );

      if (rows.isEmpty) {
        await _syncEverydayReportsFromTasks(txn);
        rows = await txn.query(
          everydayReportsTable,
          columns: [columnCompletedCount],
          where: '$columnTitle = ? AND $columnDescription = ?',
          whereArgs: [normalizedTitle, normalizedDescription],
          limit: 1,
        );
        if (rows.isEmpty) return;
      }

      final currentCount = rows.first[columnCompletedCount] as int? ?? 0;
      final nextCount = currentCount + delta;
      await txn.update(
        everydayReportsTable,
        {columnCompletedCount: nextCount < 0 ? 0 : nextCount},
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [normalizedTitle, normalizedDescription],
      );

      final monthDate = _tryParseTaskDate(date ?? '') ?? DateTime.now();
      final month = DateFormat('yyyy-M').format(monthDate);
      final monthRows = await txn.query(
        everydayReportMonthsTable,
        columns: [columnCompletedCount],
        where:
            '$columnTitle = ? AND $columnDescription = ? AND $columnMonth = ?',
        whereArgs: [normalizedTitle, normalizedDescription, month],
        limit: 1,
      );

      if (monthRows.isEmpty) {
        await txn.insert(
          everydayReportMonthsTable,
          {
            columnTitle: normalizedTitle,
            columnDescription: normalizedDescription,
            columnMonth: month,
            columnCompletedCount: delta > 0 ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        return;
      }

      final currentMonthCount =
          monthRows.first[columnCompletedCount] as int? ?? 0;
      final nextMonthCount = currentMonthCount + delta;
      await txn.update(
        everydayReportMonthsTable,
        {columnCompletedCount: nextMonthCount < 0 ? 0 : nextMonthCount},
        where:
            '$columnTitle = ? AND $columnDescription = ? AND $columnMonth = ?',
        whereArgs: [normalizedTitle, normalizedDescription, month],
      );
    });
  }

  Future<void> _renameEverydayReport(
    DatabaseExecutor db,
    String oldTitle,
    String oldDescription,
    String newTitle,
    String newDescription,
  ) async {
    if (oldTitle.isEmpty ||
        _everydayReportKey(oldTitle, oldDescription) ==
            _everydayReportKey(newTitle, newDescription)) {
      return;
    }

    final oldReports = await db.query(
      everydayReportsTable,
      where: '$columnTitle = ? AND $columnDescription = ?',
      whereArgs: [oldTitle, oldDescription],
      limit: 1,
    );
    if (oldReports.isEmpty) return;

    final newReports = await db.query(
      everydayReportsTable,
      where: '$columnTitle = ? AND $columnDescription = ?',
      whereArgs: [newTitle, newDescription],
      limit: 1,
    );

    if (newReports.isEmpty) {
      await db.update(
        everydayReportsTable,
        {
          columnTitle: newTitle,
          columnDescription: newDescription,
        },
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [oldTitle, oldDescription],
      );
      await db.update(
        everydayReportMonthsTable,
        {
          columnTitle: newTitle,
          columnDescription: newDescription,
        },
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [oldTitle, oldDescription],
      );
      return;
    }

    final oldStartDate =
        _tryParseTaskDate((oldReports.first[columnStartDate] ?? '').toString());
    final newStartDate =
        _tryParseTaskDate((newReports.first[columnStartDate] ?? '').toString());
    final mergedStartDate = _earliestDate(oldStartDate, newStartDate);
    final mergedCompletedCount =
        (oldReports.first[columnCompletedCount] as int? ?? 0) +
            (newReports.first[columnCompletedCount] as int? ?? 0);

    await db.update(
      everydayReportsTable,
      {
        columnStartDate: DateFormat('yyyy-M-d').format(mergedStartDate),
        columnTotalCount: _getEverydayTotalCount(mergedStartDate),
        columnCompletedCount: mergedCompletedCount,
      },
      where: '$columnTitle = ? AND $columnDescription = ?',
      whereArgs: [newTitle, newDescription],
    );

    final oldMonthRows = await db.query(
      everydayReportMonthsTable,
      where: '$columnTitle = ? AND $columnDescription = ?',
      whereArgs: [oldTitle, oldDescription],
    );

    for (final oldMonthRow in oldMonthRows) {
      final month = (oldMonthRow[columnMonth] ?? '').toString();
      final oldCount = oldMonthRow[columnCompletedCount] as int? ?? 0;
      final newMonthRows = await db.query(
        everydayReportMonthsTable,
        where:
            '$columnTitle = ? AND $columnDescription = ? AND $columnMonth = ?',
        whereArgs: [newTitle, newDescription, month],
        limit: 1,
      );

      if (newMonthRows.isEmpty) {
        await db.update(
          everydayReportMonthsTable,
          {
            columnTitle: newTitle,
            columnDescription: newDescription,
          },
          where: '$columnId = ?',
          whereArgs: [oldMonthRow[columnId]],
        );
      } else {
        final newCount = newMonthRows.first[columnCompletedCount] as int? ?? 0;
        await db.update(
          everydayReportMonthsTable,
          {columnCompletedCount: oldCount + newCount},
          where: '$columnId = ?',
          whereArgs: [newMonthRows.first[columnId]],
        );
        await db.delete(
          everydayReportMonthsTable,
          where: '$columnId = ?',
          whereArgs: [oldMonthRow[columnId]],
        );
      }
    }

    await db.delete(
      everydayReportsTable,
      where: '$columnTitle = ? AND $columnDescription = ?',
      whereArgs: [oldTitle, oldDescription],
    );
  }

  Future<void> _syncEverydayReportsFromTasks(DatabaseExecutor db) async {
    final tasks = await db.query(tableName);
    final activeEverydayTasks =
        tasks.where((task) => task[columnRepeat] == "Everyday").toList();
    final activeKeys = <String>{};

    for (final everydayTask in activeEverydayTasks) {
      final title = (everydayTask[columnTitle] ?? '').toString().trim();
      final description =
          (everydayTask[columnDescription] ?? '').toString().trim();
      final key = _everydayReportKey(title, description);
      if (!activeKeys.add(key)) continue;

      final existingReports = await db.query(
        everydayReportsTable,
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [title, description],
        limit: 1,
      );

      final relatedTasks = tasks.where((task) {
        return (task[columnTitle] ?? '').toString().trim() == title &&
            (task[columnDescription] ?? '').toString().trim() == description;
      }).toList();

      final parsedDates = relatedTasks
          .map((task) => _tryParseTaskDate((task[columnDate] ?? '').toString()))
          .whereType<DateTime>()
          .toList()
        ..sort();

      if (parsedDates.isEmpty) continue;

      final storedStartDate = existingReports.isNotEmpty
          ? _tryParseTaskDate(
              (existingReports.first[columnStartDate] ?? '').toString())
          : null;
      final startDate = storedStartDate ?? parsedDates.first;
      final totalCount = _getEverydayTotalCount(startDate);
      final completedFromTasks =
          relatedTasks.where((task) => task[columnIsDone] == 1).length;
      final completedCount = existingReports.isNotEmpty
          ? existingReports.first[columnCompletedCount] as int? ?? 0
          : completedFromTasks;

      await db.insert(
        everydayReportsTable,
        {
          columnTitle: title,
          columnDescription: description,
          columnStartDate: DateFormat('yyyy-M-d').format(startDate),
          columnTotalCount: totalCount,
          columnCompletedCount: completedCount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await _syncEverydayReportMonthsFromTasks(db, tasks, activeKeys);
    await _deleteExpiredEverydayReportMonths(db, activeKeys);

    final reports = await db.query(everydayReportsTable);
    for (final report in reports) {
      final key = _everydayReportKey(
        (report[columnTitle] ?? '').toString().trim(),
        (report[columnDescription] ?? '').toString().trim(),
      );
      if (!activeKeys.contains(key)) {
        await _cleanupInactiveEverydayReport(
          db,
          (report[columnTitle] ?? '').toString().trim(),
          (report[columnDescription] ?? '').toString().trim(),
          keepHistoricalMonths: true,
        );
      }
    }

    await _syncAggregateEverydayReportCounts(db);
  }

  Future<void> _syncAggregateEverydayReportCounts(DatabaseExecutor db) async {
    final reports = await db.query(everydayReportsTable);
    for (final report in reports) {
      final title = (report[columnTitle] ?? '').toString().trim();
      final description = (report[columnDescription] ?? '').toString().trim();
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM($columnCompletedCount), 0) '
        'FROM $everydayReportMonthsTable '
        'WHERE $columnTitle = ? AND $columnDescription = ?',
        [title, description],
      );

      await db.update(
        everydayReportsTable,
        {columnCompletedCount: Sqflite.firstIntValue(result) ?? 0},
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [title, description],
      );
    }
  }

  Future<void> _syncEverydayReportMonthsFromTasks(DatabaseExecutor db,
      List<Map<String, dynamic>> tasks, Set<String> activeKeys) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final activeEverydayTasks =
        tasks.where((task) => task[columnRepeat] == "Everyday").toList();
    final activeMonthKeys = <String>{};

    for (final everydayTask in activeEverydayTasks) {
      final title = (everydayTask[columnTitle] ?? '').toString().trim();
      final description =
          (everydayTask[columnDescription] ?? '').toString().trim();
      final reportKey = _everydayReportKey(title, description);
      if (!activeKeys.contains(reportKey)) continue;

      final relatedTasks = tasks.where((task) {
        return (task[columnTitle] ?? '').toString().trim() == title &&
            (task[columnDescription] ?? '').toString().trim() == description;
      }).toList();

      final parsedDates = relatedTasks
          .map((task) => _tryParseTaskDate((task[columnDate] ?? '').toString()))
          .whereType<DateTime>()
          .toList()
        ..sort();
      if (parsedDates.isEmpty) continue;

      final aggregateRows = await db.query(
        everydayReportsTable,
        columns: [columnStartDate],
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [title, description],
        limit: 1,
      );
      final aggregateStartDate = aggregateRows.isNotEmpty
          ? _tryParseTaskDate(
              (aggregateRows.first[columnStartDate] ?? '').toString())
          : null;
      DateTime cursor = _monthOnly(aggregateStartDate ?? parsedDates.first);
      final retentionStart = _sixMonthWindowStart();
      if (cursor.isBefore(retentionStart)) {
        cursor = retentionStart;
      }

      while (!cursor.isAfter(currentMonth)) {
        final month = DateFormat('yyyy-M').format(cursor);
        final monthKey = '$reportKey|$month';
        activeMonthKeys.add(monthKey);

        final existingMonthRows = await db.query(
          everydayReportMonthsTable,
          columns: [columnCompletedCount],
          where:
              '$columnTitle = ? AND $columnDescription = ? AND $columnMonth = ?',
          whereArgs: [title, description, month],
          limit: 1,
        );

        final completedFromTasks = relatedTasks.where((task) {
          final taskDate =
              _tryParseTaskDate((task[columnDate] ?? '').toString());
          return task[columnIsDone] == 1 &&
              taskDate != null &&
              taskDate.year == cursor.year &&
              taskDate.month == cursor.month;
        }).length;
        final completedCount = existingMonthRows.isNotEmpty
            ? existingMonthRows.first[columnCompletedCount] as int? ?? 0
            : completedFromTasks;

        await db.insert(
          everydayReportMonthsTable,
          {
            columnTitle: title,
            columnDescription: description,
            columnMonth: month,
            columnCompletedCount: completedCount,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        cursor = _addMonths(cursor, 1);
      }
    }

    final monthRows = await db.query(everydayReportMonthsTable);
    for (final row in monthRows) {
      final rowKey = '${_everydayReportKey(
        (row[columnTitle] ?? '').toString().trim(),
        (row[columnDescription] ?? '').toString().trim(),
      )}|${row[columnMonth]}';
      if (!activeMonthKeys.contains(rowKey)) {
        final now = DateTime.now();
        final currentMonth = DateFormat('yyyy-M').format(now);
        final completedCount = row[columnCompletedCount] as int? ?? 0;
        if (row[columnMonth] == currentMonth && completedCount <= 0) {
          await db.delete(
            everydayReportMonthsTable,
            where: '$columnId = ?',
            whereArgs: [row[columnId]],
          );
        }
      }
    }
  }

  Future<void> _cleanupInactiveEverydayReport(
      DatabaseExecutor db, String title, String description,
      {bool keepHistoricalMonths = false}) async {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-M').format(now);

    await db.delete(
      everydayReportMonthsTable,
      where:
          '$columnTitle = ? AND $columnDescription = ? AND $columnMonth = ? AND $columnCompletedCount <= 0',
      whereArgs: [title, description, currentMonth],
    );

    if (!keepHistoricalMonths) {
      final cutoffMonth = DateFormat('yyyy-M').format(_sixMonthWindowStart());
      final monthRows = await db.query(
        everydayReportMonthsTable,
        columns: [columnId, columnMonth],
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [title, description],
      );
      for (final row in monthRows) {
        final rowMonth = _tryParseMonth((row[columnMonth] ?? '').toString());
        final cutoff = _tryParseMonth(cutoffMonth);
        if (rowMonth != null && cutoff != null && rowMonth.isBefore(cutoff)) {
          await db.delete(
            everydayReportMonthsTable,
            where: '$columnId = ?',
            whereArgs: [row[columnId]],
          );
        }
      }
    }

    final remainingMonths = await db.query(
      everydayReportMonthsTable,
      where: '$columnTitle = ? AND $columnDescription = ?',
      whereArgs: [title, description],
      limit: 1,
    );

    if (remainingMonths.isEmpty) {
      await db.delete(
        everydayReportsTable,
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [title, description],
      );
    }
  }

  Future<void> _deleteExpiredEverydayReportMonths(
    DatabaseExecutor db,
    Set<String> activeKeys,
  ) async {
    final cutoff = _sixMonthWindowStart();
    final rows = await db.query(everydayReportMonthsTable);

    for (final row in rows) {
      final monthDate = _tryParseMonth((row[columnMonth] ?? '').toString());
      if (monthDate == null || !monthDate.isBefore(cutoff)) continue;

      await db.delete(
        everydayReportMonthsTable,
        where: '$columnId = ?',
        whereArgs: [row[columnId]],
      );
    }

    final reports = await db.query(everydayReportsTable);
    for (final report in reports) {
      final title = (report[columnTitle] ?? '').toString().trim();
      final description = (report[columnDescription] ?? '').toString().trim();
      final reportKey = _everydayReportKey(title, description);
      if (activeKeys.contains(reportKey)) continue;

      final remainingMonths = await db.query(
        everydayReportMonthsTable,
        where: '$columnTitle = ? AND $columnDescription = ?',
        whereArgs: [title, description],
        limit: 1,
      );
      if (remainingMonths.isEmpty) {
        await db.delete(
          everydayReportsTable,
          where: '$columnId = ?',
          whereArgs: [report[columnId]],
        );
      }
    }
  }

  String _everydayReportKey(String title, String description) {
    return '$title|$description';
  }

  DateTime? _tryParseTaskDate(String date) {
    try {
      return DateFormat('yyyy-M-d').parse(date);
    } catch (e) {
      return null;
    }
  }

  int _getEverydayTotalCount(DateTime startDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (start.isAfter(today)) return 0;
    return today.difference(start).inDays + 1;
  }

  int _maxInt(int a, int b) {
    return a > b ? a : b;
  }

  DateTime _earliestDate(DateTime? first, DateTime? second) {
    if (first == null && second == null) {
      return DateTime.now();
    }
    if (first == null) return second!;
    if (second == null) return first;
    return first.isBefore(second) ? first : second;
  }

  DateTime _monthOnly(DateTime date) {
    return DateTime(date.year, date.month);
  }

  DateTime _sixMonthWindowStart() {
    final now = DateTime.now();
    return _addMonths(DateTime(now.year, now.month), -5);
  }

  DateTime _addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months);
  }

  DateTime? _tryParseMonth(String month) {
    try {
      return DateFormat('yyyy-M').parse(month);
    } catch (e) {
      return null;
    }
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }
}
