import 'dart:async';

import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/Database.dart';
import 'package:doit/utils/FileManager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppProvider extends ChangeNotifier {
  final AppDatabase database = AppDatabase.instance;
  final FileManager fileManager = FileManager.instance;

  List<Task> tasks = [];
  List<String> historyDatesOfAllTaskCompletion = [];
  bool celebrationShown = false;
  bool dailyGoalAchieved = false;

  bool isNotificationsEnabled = true;

  List<int> taskIds = [];

  List<Map<String, dynamic>> completedTasksByDay = [];

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get isReady => _initCompleter.future;

  AppProvider() {
    _initInternal();
  }

  Future<void> _initInternal() async {
    await loadTasks();
    await loadHistory();
    await loadSettings();
    _checkForIncompleteTaskAndShift___AND___checkForEverydayTask();
    // _historyUpdate();
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

  void _checkForIncompleteTaskAndShift(task) async {
    if (!task.isDone) {
      // If the task is not done, shift it to the next day
      String taskDate = DateFormat('yyyy-M-d').format(DateTime.now());
      if (taskDate != task.date) {
        await database.updateTask(task.id, task.title, task.description,
            task.isDone ? 1 : 0, task.repeat, taskDate, task.time ?? 'None');
      }
    }
  }

  void _checkForEverydayTask(task) async {
    if (task.repeat == "Everyday" && task.isDone) {
      String taskDate = DateFormat('yyyy-M-d').format(DateTime.now());
      if (!taskIds.contains(task.id) && task.date != taskDate) {
        await database.addTask(task.title, task.description, 0, task.repeat,
            taskDate, task.time ?? 'None');
        await database.updateTask(task.id, task.title, task.description, 1,
            "Once", task.date, task.time ?? 'None');
        taskIds.add(task.id);
      }
    }
  }

  void _checkForIncompleteTaskAndShift___AND___checkForEverydayTask() async {
    //Check for the incomplete task in the list and chnage the date to the next day
    for (var task in tasks) {
      _checkForIncompleteTaskAndShift(task);
      _checkForEverydayTask(task);
    }
    await loadTasks();
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
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    completedTasksByDay.clear();

    for (var task in tasks) {
      final taskDate = DateFormat('yyyy-M-d').parse(task.date);
      if (taskDate.isBefore(sevenDaysAgo)) {
        database.deleteTask(task.id);
        continue; // Skip tasks older than 7 days
      }
      if (isSameDate(taskDate, now)) {
        continue;
      }

      // Find or create the entry for the task's day
      final dayKey = DateFormat('MMMM d, yyyy').format(taskDate);
      final dayEntry = completedTasksByDay.firstWhere(
          (entry) => entry['day'] == dayKey,
          orElse: () =>
              {'day': dayKey, 'isAllTaskCompletedDay': false, 'tasks': []});
      if (historyDatesOfAllTaskCompletion
          .contains(DateFormat('yyyy-M-d').format(taskDate))) {
        dayEntry['isAllTaskCompletedDay'] = true;
      }

      task.isDone ? dayEntry['tasks'].add(task.title) : null;

      if (!completedTasksByDay.contains(dayEntry)) {
        completedTasksByDay.add(dayEntry);
      }
    }
    completedTasksByDay = completedTasksByDay.reversed.toList();
  }
}
