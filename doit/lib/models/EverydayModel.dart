// ignore_for_file: file_names

import 'package:intl/intl.dart';

class EverydayReport {
  final String title;
  final String description;
  final int completedCount;
  final int totalCount;
  final DateTime firstDate;
  final DateTime latestDate;

  const EverydayReport({
    required this.title,
    required this.description,
    required this.completedCount,
    required this.totalCount,
    required this.firstDate,
    required this.latestDate,
  });

  factory EverydayReport.fromMap(Map<String, dynamic> map) {
    final startDate = DateFormat('yyyy-M-d').parse(map['startDate'] as String);

    return EverydayReport(
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      completedCount: map['completedCount'] as int? ?? 0,
      totalCount: map['totalCount'] as int? ?? 0,
      firstDate: startDate,
      latestDate: startDate,
    );
  }

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}
