// home_page.dart
import 'package:doit/components/CelebrationsPage.dart';
import 'package:doit/components/TaskCompletionOverlay.dart';
import 'package:doit/components/TaskEditorPage.dart';
import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/AssistingFunctions.dart';
import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Database.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

/*
showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => const TaskCompletionOverlay(),
  );



  {id: 1, title: Test task, description: sds, isDone: 0, repeat: Once, date: 2025-8-17, time: None}
*/

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDatabase database = AppDatabase.instance;

  int _progressValue = 0;

  String screenTitle = "Today's Tasks";

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        checkUpdate(context);
      } catch (e) {
        print("Error while checking update...");
      }
    });
    super.initState();
  }

  void _checkForIncompleteTaskAndShift(appProvider) {
    //Check for the incomplete task in the list and chnage the date to the next day
    for (var task in appProvider.tasks) {
      if (!task.isDone) {
        // If the task is not done, shift it to the next day
        String taskDate = DateFormat('yyyy-M-d').format(DateTime.now());
        database.updateTask(task.id, task.title, task.description,
            task.isDone ? 1 : 0, task.repeat, taskDate, task.time ?? 'None');
      }
    }
  }

  void updatePercentage(appProvider) {
    _progressValue =
        getPercentage(getCurrentLevel(appProvider.tasks), appProvider.tasks);
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

  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      _checkForIncompleteTaskAndShift(appProvider);
      updatePercentage(appProvider);
      //Check if not task if there for today show the modal
      if (appProvider.tasks.isNotEmpty &&
          _getTodayIncompleteTasksCount(appProvider.tasks) == 0) {
        // Add the date in the history table
        try {
          String date = DateFormat('yyyy-M-d').format(DateTime.now());
          database.addToHistory(
            date,
          );
          // appProvider.loadHistory();
        } catch (e) {}
        if (!appProvider.dailyGoalAchieved) {
          appProvider.dailyGoalAchieved = true;
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (context) => const TaskCompletionOverlay(),
            );
          });
        }
        ;
      }
      // Check the level and navigate to the CelebrationPage

      if (appProvider.tasks.isNotEmpty &&
          getCompletedTaskCount(appProvider.tasks) ==
              getMaxNoOfCompletedTask(getCurrentLevel(appProvider.tasks)) &&
          !appProvider.celebrationShown) {
        appProvider.celebrationShown = !appProvider.celebrationShown;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CelebrationPage()),
          );
        });
      }
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.15), // Dark green tint
              const Color(0xFF0A1A0F)
                  .withValues(alpha: 0.6), // Deep forest green
            ],
            stops: const [0.4, 1.0],
            transform: const GradientRotation(0.1),
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text(
                screenTitle,
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: Colors.grey.withValues(alpha: 0.5)),
                  color: surfaceColor.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.2), width: 1),
                  ),
                  elevation: 4,
                  onSelected: (value) {
                    if (value == 'today') {
                      // Handle Today's Tasks action
                      setState(() {
                        screenTitle = "Today's Tasks";
                      });
                    } else if (value == 'inbox') {
                      // Handle Inbox action
                      setState(() {
                        screenTitle = "Inbox";
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'today',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            "Today's Tasks",
                            style: GoogleFonts.nunitoSans(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'inbox',
                      child: Row(
                        children: [
                          Icon(Icons.inbox, color: primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            'Inbox',
                            style: GoogleFonts.nunitoSans(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),

            // Progress Section
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withValues(alpha: 0.9),
                            ),
                            child: const Icon(Icons.rocket_launch,
                                color: Colors.black, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            getLevelMessage(appProvider.tasks),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 170,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progressValue / 100.0,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  primaryColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 40.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "$_progressValue% Complete",
                            style: GoogleFonts.nunitoSans(
                              color: textPrimary.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Task List Header
            SliverPadding(
              padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "My Tasks",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // Task List
            SliverList(
              delegate: (screenTitle == "Inbox" && appProvider.tasks.isEmpty) ||
                      (screenTitle == "Today's Tasks" &&
                          _getTodayTasksCount(appProvider.tasks) == 0)
                  ? SliverChildListDelegate([
                      Column(
                        children: [
                          // Premium animation
                          Lottie.asset(
                            'assets/json/EmptyState.json',
                            width: 270,
                            height: 170,
                            repeat: true,
                          ),
                          const SizedBox(height: 30),
                          // Title
                          Text(
                            "All Caught Up!",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Subtitle
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Text(
                              "Add your first task to start your productivity journey",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ])
                  : SliverChildBuilderDelegate(
                      (context, index) {
                        final task = appProvider.tasks.reversed.toList()[index];
                        final taskDate =
                            DateFormat('yyyy-M-d').parse(task.date);
                        if (screenTitle == "Today's Tasks") {
                          //Filter out only today's task
                          if (isSameDate(taskDate, DateTime.now())) {
                            return _buildTaskTile(
                              task: task,
                              appProvider: appProvider,
                              title: task.title,
                              isDone: task.isDone,
                              onChanged: (value) {
                                // Set the tasks isDone to true
                                database.updateTask(
                                    task.id,
                                    task.title,
                                    task.description,
                                    value! ? 1 : 0,
                                    task.repeat,
                                    task.date,
                                    task.time != null ? task.time! : "None");
                                setState(() {
                                  task.isDone = value;
                                });
                                !value
                                    ? database.removeFromHistory(
                                        DateFormat('yyyy-M-d').format(taskDate))
                                    : null;
                                appProvider.loadHistory();
                              },
                              primaryColor: primaryColor,
                              surfaceColor: surfaceColor,
                              textPrimary: textPrimary,
                            );
                          }
                        } else {
                          return _buildTaskTile(
                            task: task,
                            state: "Inbox",
                            appProvider: appProvider,
                            title: task.title,
                            isDone: task.isDone,
                            onChanged: (value) {
                              // Set the tasks isDone to true
                              database.updateTask(
                                  task.id,
                                  task.title,
                                  task.description,
                                  value! ? 1 : 0,
                                  task.repeat,
                                  task.date,
                                  task.time != null ? task.time! : "None");
                              setState(() {
                                task.isDone = value;
                              });
                              !value
                                  ? database.removeFromHistory(
                                      DateFormat('yyyy-M-d').format(taskDate))
                                  : null;
                              appProvider.loadHistory();
                            },
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textPrimary: textPrimary,
                          );
                        }
                        return null;
                      },
                      childCount: appProvider.tasks.length,
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      );
    });
  }

  // Sleek Task Tile
  Widget _buildTaskTile({
    Task? task,
    String state = "Today's Task",
    required AppProvider appProvider,
    required String title,
    required bool isDone,
    required Function(bool?) onChanged,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: () => !isDone
          ? Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskEditorPage(
                  task: task,
                ),
              ),
            )
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minVerticalPadding: 0,
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? accentColor : Colors.grey,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(!isDone),
                child: isDone
                    ? Icon(Icons.check, size: 16, color: accentColor)
                    : null,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? Colors.grey.withValues(alpha: 0.4)
                        : textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (state == "Inbox")
                Text(
                  DateFormat('MMM d').format(DateFormat('yyyy-M-d')
                      .parse(task!.date)), // Format the date
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? Colors.grey.withValues(alpha: 0.3)
                        : textPrimary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Colors.grey.withValues(alpha: 0.5)),
            color: surfaceColor.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: primaryColor.withValues(alpha: 0.2), width: 1),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                database.deleteTask(task!.id);
                appProvider.loadTasks();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red[300]),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Task',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.red[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
