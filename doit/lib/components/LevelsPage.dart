import 'package:doit/models/LevelModel.dart';
import 'package:doit/utils/AssistingFunctions.dart';
import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LevelsPage extends StatefulWidget {
  const LevelsPage({super.key});

  @override
  State<LevelsPage> createState() => _LevelsPageState();
}

class _LevelsPageState extends State<LevelsPage> {
  final List<Level> _levels = [];

  void _loadLevels(appProvider) {
    _levels.clear();
    int level = getCurrentLevel(appProvider.tasks);
    int i = 1;
    while (i <= level + 3) {
      if (i < level) {
        _levels.add(Level(
            number: i,
            taskGoal: getMaxNoOfCompletedTask(i),
            currentTasks: getMaxNoOfCompletedTask(i),
            reward: generateRewardName(i),
            state: LevelState.completed));
      } else if (i == level) {
        _levels.add(Level(
            number: i,
            taskGoal: getMaxNoOfCompletedTask(i),
            currentTasks: getCompletedTaskCount(appProvider.tasks),
            reward: "",
            state: LevelState.inProgress));
      } else {
        _levels.add(Level(
            number: i,
            taskGoal: getMaxNoOfCompletedTask(i),
            currentTasks: 0,
            reward: "",
            state: LevelState.locked));
      }

      i++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        _loadLevels(appProvider);
        return Scaffold(
          body: Container(
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
            child: Container(
              margin: EdgeInsets.only(bottom: 50),
              child: CustomScrollView(
                slivers: [
                  // --- Modern App Bar ---
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    title: Text(
                      'Levels Achieved',
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    centerTitle: false,
                    actions: [
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
                                              Icon(Icons.rocket_launch,
                                                  size: 24,
                                                  color: primaryColor),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Level Progress",
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
                                            "Your level increases as you complete tasks. Each level unlocks new achievements and rewards. Complete ${getMaxNoOfCompletedTask(getCurrentLevel(appProvider.tasks)) - getCompletedTaskCount(appProvider.tasks)} tasks to reach Level ${getCurrentLevel(appProvider.tasks) + 1}.",
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

                  // --- Level Path Visualization ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Stack(
                        children: [
                          // --- The Center Path Line ---
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: MediaQuery.of(context).size.width / 2 - 1.5,
                            child: Container(
                              width: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    primaryColor.withValues(alpha: 0.6),
                                    primaryColor.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // --- Level Nodes ---
                          Column(
                            children: List.generate(_levels.length, (index) {
                              final level = _levels[index];
                              return _LevelNode(level: level);
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LevelNode extends StatelessWidget {
  final Level level;
  const _LevelNode({required this.level});

  @override
  Widget build(BuildContext context) {
    final double progress =
        level.taskGoal > 0 ? level.currentTasks / level.taskGoal : 0;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left decoration for even levels
          if (level.number.isEven) ...[
            _buildPathDecoration(true, context),
            const SizedBox(width: 20),
          ],

          // Level Node
          Container(
            width: isMobile ? 100 : 140,
            height: isMobile ? 100 : 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor.withValues(alpha: 0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Progress ring for in-progress levels
                if (level.state == LevelState.inProgress)
                  SizedBox(
                    width: isMobile ? 110 : 150,
                    height: isMobile ? 110 : 150,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      color: primaryColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),

                // Level content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "LEVEL",
                      style: GoogleFonts.nunitoSans(
                        fontSize: isMobile ? 12 : 14,
                        color: textPrimary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      level.number.toString(),
                      style: GoogleFonts.nunitoSans(
                        fontSize: isMobile ? 32 : 42,
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                // Reward badge for completed levels
                if (level.state == LevelState.completed)
                  Positioned(
                    top: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star,
                              size: isMobile ? 16 : 18, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            "Unlocked",
                            style: GoogleFonts.nunitoSans(
                              fontSize: isMobile ? 12 : 13,
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Lock icon for locked levels
                if (level.state == LevelState.locked)
                  Positioned(
                    bottom: -15,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.5)),
                      ),
                      child: Icon(Icons.lock_outline,
                          size: isMobile ? 18 : 22, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),

          // Right decoration for odd levels
          if (level.number.isOdd) ...[
            const SizedBox(width: 20),
            _buildPathDecoration(false, context),
          ],
        ],
      ),
    );
  }

  Widget _buildPathDecoration(bool isLeft, BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${level.currentTasks}/${level.taskGoal}",
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            color: textPrimary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (level.state == LevelState.completed) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 100,
            child: Text(
              level.reward,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ],
    );
  }
}
