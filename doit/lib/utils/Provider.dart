import 'dart:async';
import 'dart:developer';

import 'package:doit/models/EverydayModel.dart';
import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/Database.dart';
import 'package:doit/utils/FileManager.dart';
import 'package:doit/utils/Notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppProvider extends ChangeNotifier {
  final AppDatabase database = AppDatabase.instance;
  final FileManager fileManager = FileManager.instance;
  bool _hasInitialized = false;

  List<Task> tasks = [];
  List<String> historyDatesOfAllTaskCompletion = [];
  bool celebrationShown = false;
  bool dailyGoalAchieved = false;

  bool isNotificationsEnabled = true;

  List<Map<String, dynamic>> completedTasksByDay = [];
  List<EverydayReport> everydayReports = [];

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get isReady => _initCompleter.future;

  AppProvider(isProcessing) {
    if (isProcessing != null) _initInternal(isProcessing);
  }

  Future<void> _initInternal(isProcessing) async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    await loadTasks();
    await loadHistory();
    await loadSettings();
    await checkForIncompleteTaskAndShift___AND___checkForEverydayTask(
        isProcessing);
    await loadEverydayReports();
    _loadCompletedTasksHistory();
    _initCompleter.complete();
  }

  Future<void> loadTasks() async {
    final fetchedTasks = await database.getAllTasks();
    tasks.clear();
    for (var task in fetchedTasks) {
      tasks.add(Task(
        id: task['id'],
        title: task['title'],
        description: task['description'],
        isDone: task['isDone'] == 1,
        repeat: task['repeat'],
        date: task['date'],
        time: task['time'] == "None" ? null : task['time'],
      ));
    }
    notifyListeners();
  }

  Future<void> loadHistory() async {
    try {
      final list = await database.getAllHistory();
      historyDatesOfAllTaskCompletion = List<String>.from(list);
      notifyListeners();
    } catch (e) {}
  }

  Future<void> loadEverydayReports() async {
    try {
      final reports = await database.getEverydayReports();
      everydayReports =
          reports.map((report) => EverydayReport.fromMap(report)).toList();
      everydayReports.sort((a, b) {
        final progressCompare = a.progress.compareTo(b.progress);
        if (progressCompare != 0) return progressCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      notifyListeners();
    } catch (e) {}
  }

  Future<void> loadSettings() async {
    try {
      final settings = await fileManager.getUserSettings();
      print("CHECKING");
      print(settings);
      if (settings != null) {
        isNotificationsEnabled = settings['isNotificationsEnabled'] ?? true;
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> _checkForIncompleteTaskAndShift(task) async {
    if (!task.isDone) {
      // If the task is not done, shift it to the next day
      String taskDate = DateFormat('yyyy-M-d').format(DateTime.now());
      if (taskDate != task.date) {
        await database.updateTask(task.id, task.title, task.description,
            task.isDone ? 1 : 0, task.repeat, taskDate, task.time ?? 'None');
      }
    }
  }

  Future<void> _checkForEverydayTask(task) async {
    if (task.repeat == "Everyday" && task.isDone) {
      String taskDate = DateFormat('yyyy-M-d').format(DateTime.now());
      if (task.date != taskDate) {
        // THE CRITICAL CHECK: Ask the database if this title/date combo exists
        final db = await database.database;
        final existing = await db.query(
          'tasks',
          where: 'title = ? AND date = ?',
          whereArgs: [task.title, taskDate],
        );

        if (existing.isEmpty) {
          final int newTaskId = await database.addTask(task.title,
              task.description, 0, task.repeat, taskDate, task.time ?? 'None');
          await database.updateTask(task.id, task.title, task.description, 1,
              "Once", task.date, task.time ?? 'None');
          try {
            if (task.time != null && isNotificationsEnabled) {
              final List<String> timeParts = task.time!.split(":");
              Notifications().scheduleNotifications(
                  id: newTaskId,
                  title: task.title,
                  body: task.description,
                  scheduledDate: DateFormat('yyyy-M-d').parse(taskDate),
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]));
            }
          } catch (e) {
            log("Error setting the notification");
          }
        }
      }
    }
  }

  Future<void> checkForIncompleteTaskAndShift___AND___checkForEverydayTask(
      isProcessing) async {
    //Check for the incomplete task in the list and chnage the date to the next day
    if (isProcessing || isProcessing == null) return;
    isProcessing = true;
    for (var task in tasks) {
      await _checkForIncompleteTaskAndShift(task);
      await _checkForEverydayTask(task);
    }
    await loadTasks();
    await database.syncEverydayReportsFromTasks();
    await loadEverydayReports();
  }

  int _getTodayIncompleteTasksCount(List<Task> tasks) {
    DateTime now = DateTime.now();
    return tasks.where((task) {
      DateTime taskDate = DateFormat('yyyy-M-d').parse(task.date);
      return taskDate.year == now.year &&
          taskDate.month == now.month &&
          taskDate.day == now.day &&
          !task.isDone;
    }).length;
  }

  //filter todays task from appProvider.tasks and return the count
  int _getTodayTasksCount(List<Task> tasks) {
    DateTime now = DateTime.now();
    return tasks.where((task) {
      DateTime taskDate = DateFormat('yyyy-M-d').parse(task.date);
      return taskDate.year == now.year &&
          taskDate.month == now.month &&
          taskDate.day == now.day;
    }).length;
  }

  // void _historyUpdate() {
  //   if (tasks.isNotEmpty &&
  //       _getTodayIncompleteTasksCount(tasks) == 0 &&
  //       _getTodayTasksCount(tasks) > 0) {
  //     // Add the date in the history table
  //     try {
  //       String date = DateFormat('yyyy-M-d').format(DateTime.now());
  //       database.addToHistory(
  //         date,
  //       );
  //       // appProvider.loadHistory();
  //     } catch (e) {}
  //   }
  // }

  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _loadCompletedTasksHistory() {
    final now = DateTime.now();
    final daysAgo =
        now.subtract(Duration(days: 30)); // Changing to 30 days from 7 days

    completedTasksByDay.clear();

    for (var task in tasks) {
      final taskDate = DateFormat('yyyy-M-d').parse(task.date);
      if (taskDate.isBefore(daysAgo) && task.isDone) {
        database.deleteTask(task.id);
        continue; // Skip tasks older than 30 days
      }
      if (isSameDate(taskDate, now)) {
        continue;
      }

      // Find or create the entry for the task's day
      final dateKey = DateFormat('yyyy-M-d').format(taskDate);
      final dayKey = DateFormat('MMMM d, yyyy').format(taskDate);
      final dayEntry = completedTasksByDay.firstWhere(
          (entry) => entry['dateKey'] == dateKey,
          orElse: () => {
                'dateKey': dateKey,
                'day': dayKey,
                'isAllTaskCompletedDay': false,
                'tasks': []
              });
      if (historyDatesOfAllTaskCompletion.contains(dateKey)) {
        dayEntry['isAllTaskCompletedDay'] = true;
      }

      task.isDone ? dayEntry['tasks'].add(task.title) : null;

      if (!completedTasksByDay.contains(dayEntry)) {
        completedTasksByDay.add(
            dayEntry); // {'day': dayKey, 'isAllTaskCompletedDay': false, 'tasks': [task.title]}
      }
    }
    completedTasksByDay.sort((a, b) {
      final aDate = DateFormat('yyyy-M-d').parse(a['dateKey']);
      final bDate = DateFormat('yyyy-M-d').parse(b['dateKey']);
      return bDate.compareTo(aDate);
    });
  }

  // get the completed task count from the completed table
  Future<int> getCompletedTasksCount() async {
    // get count from completed table
    final completedTaskCount = await database.getCompletedTasksCount();
    // get count from history table
    int prevHistoryCount = 0;
    tasks.forEach((task) {
      DateTime taskDate = DateFormat('yyyy-M-d').parse(task.date);
      if (task.isDone &&
          taskDate.isBefore(DateFormat('yyyy-M-d').parse("2026-4-3"))) {
        prevHistoryCount++;
      }
    });
    return completedTaskCount + prevHistoryCount;
  }
}
