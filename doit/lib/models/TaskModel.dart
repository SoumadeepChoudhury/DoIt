class Task {
  int id;
  String title;
  String description;
  bool isDone;
  String repeat;
  String date;
  String? time;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.repeat,
    required this.date,
    this.time,
  });
}
