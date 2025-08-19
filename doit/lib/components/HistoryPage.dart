import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Database.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
/*
{
      'day': 'Today',
      'tasks': [
        'Design the app icon',
        'Create a splash screen',
      ],
    },
*/
  AppDatabase database = AppDatabase.instance;
  List<Map<String, dynamic>> _completedTasksByDay = [];

  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _loadCompletedTasksHistory(appProvider) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    _completedTasksByDay.clear();

    for (var task in appProvider.tasks) {
      appProvider.loadHistory();
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
      final dayEntry = _completedTasksByDay.firstWhere(
          (entry) => entry['day'] == dayKey,
          orElse: () =>
              {'day': dayKey, 'isAllTaskCompletedDay': false, 'tasks': []});
      if (appProvider.historyDatesOfAllTaskCompletion
          .contains(DateFormat('yyyy-M-d').format(taskDate))) {
        dayEntry['isAllTaskCompletedDay'] = true;
      }

      task.isDone ? dayEntry['tasks'].add(task.title) : null;

      if (!_completedTasksByDay.contains(dayEntry)) {
        _completedTasksByDay.add(dayEntry);
      }
    }
    _completedTasksByDay = _completedTasksByDay.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        _loadCompletedTasksHistory(appProvider);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.15), // Dark green tint
                const Color(0xFF0A1A0F).withValues(alpha: 0.6),
              ],
              stops: const [0.4, 1.0],
              transform: const GradientRotation(0.1),
            ),
          ),
          child: Column(
            children: [
              //Modern AppBar
              Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 20, right: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        "Task History",
                        style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 25,
                            color: textPrimary,
                            letterSpacing: -0.5),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: primaryColor),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.transparent,
                            builder: (context) => Stack(
                              children: [
                                // Background dimmer
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),

                                // Tooltip positioning (adjust right and top values as needed)
                                Positioned(
                                  right: 24,
                                  top: kToolbarHeight + 16, // Below app bar
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 280,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: surfaceColor.withValues(
                                            alpha: 0.95),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: primaryColor.withValues(
                                                alpha: 0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.history,
                                                  size: 24,
                                                  color: primaryColor),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Track History",
                                                style: GoogleFonts.nunitoSans(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "We preserve your completed tasks for 7 days so you can revisit achievements. After this period, items are automatically removed to maintain a clean, focused workspace that reflects your current priorities.",
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary.withValues(
                                                  alpha: 0.9),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              style: TextButton.styleFrom(
                                                foregroundColor: primaryColor,
                                              ),
                                              child: Text(
                                                'GOT IT',
                                                style: GoogleFonts.nunitoSans(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _completedTasksByDay.isNotEmpty
                      ? ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _completedTasksByDay.length,
                          itemBuilder: (context, index) {
                            final dayData = _completedTasksByDay[index];
                            final String day = dayData['day'];
                            final bool isAllTaskCompletedDay =
                                dayData['isAllTaskCompletedDay'];
                            final List<String> tasks =
                                List<String>.from(dayData['tasks'] ?? []);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: surfaceColor.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Day Header
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          day,
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isAllTaskCompletedDay)
                                          Icon(
                                            Icons.favorite_outlined,
                                            color: Colors.red
                                                .withValues(alpha: 0.8),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // List of tasks for that day
                                    ...tasks.map((taskTitle) {
                                      return _buildCompletedTaskItem(taskTitle);
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Column(
                          children: [
                            // Premium animation
                            Lottie.asset(
                              'assets/json/EmptyGhost.json',
                              width: 270,
                              height: 270,
                              repeat: true,
                            ),
                            const SizedBox(height: 30),
                            // Title
                            Text(
                              "No Data Available!",
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // UI Widget for a single completed task item
  Widget _buildCompletedTaskItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor),
            ),
            child: Icon(Icons.check, size: 14, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunitoSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
