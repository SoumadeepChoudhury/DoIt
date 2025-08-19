import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/Database.dart';
import 'package:doit/utils/FileManager.dart';
import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  final AppDatabase database = AppDatabase.instance;
  final FileManager fileManager = FileManager.instance;

  List<Task> tasks = [];
  List<String> historyDatesOfAllTaskCompletion = [];
  bool celebrationShown = false;
  bool dailyGoalAchieved = false;

  bool isNotificationsEnabled = true;

  AppProvider() {
    loadTasks();
    loadHistory();
    loadSettings();
  }

  void loadTasks() async {
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

  void loadSettings() async {
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
}
