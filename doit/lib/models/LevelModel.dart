enum LevelState { locked, inProgress, completed }

// A model for our level data. You'll create these from your backend.
class Level {
  final int number;
  final int taskGoal;
  final int currentTasks;
  final String reward;
  final LevelState state;

  Level({
    required this.number,
    required this.taskGoal,
    required this.currentTasks,
    required this.reward,
    required this.state,
  });
}
