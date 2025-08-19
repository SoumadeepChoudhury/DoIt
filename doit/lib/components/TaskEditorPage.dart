import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Database.dart';
import 'package:doit/utils/Notifications.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TaskEditorPage extends StatefulWidget {
  final Task? task;
  const TaskEditorPage({super.key, this.task});

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  final AppDatabase database = AppDatabase.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController(text: "");
  String _repeatOption = 'Once';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _showReminderSettings = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = DateFormat('yyyy-M-d').parse(widget.task!.date);
      if (widget.task!.time != null) {
        final List<String> partsInTime = widget.task!.time!.split(":");
        _selectedTime = TimeOfDay(
            hour: int.parse(partsInTime[0]), minute: int.parse(partsInTime[1]));
      }
      _repeatOption = widget.task!.repeat;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              onPrimary: surfaceColor,
              surface: surfaceColor,
            ),
            dialogBackgroundColor: surfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              onPrimary: surfaceColor,
              surface: surfaceColor,
            ),
            dialogBackgroundColor: surfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask(appProvider) async {
    if (_titleController.text.isNotEmpty) {
      if (widget.task != null) {
        //Cancel the previous notificatio if set
        Notifications().cancelNotification(widget.task!.id);
        //Set Notifications
        _selectedTime != null && appProvider.isNotificationsEnabled
            ? Notifications().scheduleNotifications(
                id: widget.task!.id,
                title: _titleController.text,
                body: _descriptionController.text,
                scheduledDate: DateFormat('yyyy-M-d').parse(
                    '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                hour: _selectedTime!.hour,
                minute: _selectedTime!.minute)
            : null;

        // Update the task in database
        database.updateTask(
            widget.task!.id,
            _titleController.text,
            _descriptionController.text,
            0,
            _repeatOption,
            '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
            _selectedTime != null
                ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
                : "None");

        appProvider.loadTasks();
      } else {
        //Add new task in database
        final id = await database.addTask(
            _titleController.text,
            _descriptionController.text,
            0,
            _repeatOption,
            '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
            _selectedTime != null
                ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
                : "None");
        _selectedTime != null && appProvider.isNotificationsEnabled
            ? Notifications().scheduleNotifications(
                id: id,
                title: _titleController.text,
                body: _descriptionController.text,
                scheduledDate: DateFormat('yyyy-M-d').parse(
                    '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                hour: _selectedTime!.hour,
                minute: _selectedTime!.minute)
            : null;
        appProvider.loadTasks();
        try {
          database
              .removeFromHistory(DateFormat('yyyy-M-d').format(DateTime.now()));
          appProvider.loadHistory();
        } catch (e) {}
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
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
          child: CustomScrollView(
            slivers: [
              // --- App Bar ---
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  widget.task == null ? 'New Task' : 'Edit Task',
                  style: GoogleFonts.nunitoSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: textPrimary,
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.check, color: primaryColor),
                    onPressed: () => _saveTask(appProvider),
                  ),
                ],
              ),

              // --- Form Content ---
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Title Input
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 24),

                      // Description Input
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        icon: Icons.notes,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Repeat Options
                      _buildRepeatOptions(),
                      const SizedBox(height: 24),

                      // More Settings Button
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: ListTile(
                          onTap: () => setState(() =>
                              _showReminderSettings = !_showReminderSettings),
                          title: Text(
                            'Advanced Settings',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          trailing: Icon(
                            _showReminderSettings
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: primaryColor,
                          ),
                        ),
                      ),

                      // Reminder Settings Section
                      if (_showReminderSettings) ...[
                        const SizedBox(height: 16),
                        // Date Picker
                        _buildPickerCard(
                          label: 'Date',
                          value:
                              DateFormat('EEE, MMM d, y').format(_selectedDate),
                          onTap: () => _selectDate(context),
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),

                        // Time Picker
                        _buildPickerCard(
                          label: 'Time',
                          value: _selectedTime != null
                              ? _selectedTime!.format(context)
                              : "None",
                          onTap: () => _selectTime(context),
                          icon: Icons.access_time,
                        ),
                        const SizedBox(height: 24),
                        // _buildReminderSettings(),
                      ],
                      const Spacer(),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _saveTask(appProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            widget.task == null ? 'CREATE TASK' : 'UPDATE TASK',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.nunitoSans(color: textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.nunitoSans(color: textPrimary.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildPickerCard({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: primaryColor),
        title: Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            color: textPrimary.withValues(alpha: 0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: value == "None"
                    ? Colors.grey.withValues(alpha: 0.8)
                    : primaryColor,
              ),
            ),
            label == "Time" && value != "None"
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedTime = null;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      size: 16,
                    ))
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPEAT',
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRepeatButton('Once')),
            const SizedBox(width: 16),
            Expanded(child: _buildRepeatButton('Everyday')),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatButton(String option) {
    final isSelected = _repeatOption == option;
    return ElevatedButton(
      onPressed: () => setState(() => _repeatOption = option),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? primaryColor : surfaceColor.withValues(alpha: 0.7),
        foregroundColor: isSelected ? Colors.black : textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        option,
        style: GoogleFonts.nunitoSans(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Widget _buildReminderSettings() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: surfaceColor.withValues(alpha: 0.7),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'ADVANCED REMINDERS',
  //           style: GoogleFonts.nunitoSans(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w700,
  //             color: textPrimary.withValues(alpha: 0.7),
  //             letterSpacing: 1.2,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             const Icon(Icons.notifications_active, color: primaryColor),
  //             const SizedBox(width: 16),
  //             Text(
  //               'Additional reminder options coming soon',
  //               style: GoogleFonts.nunitoSans(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: textPrimary.withValues(alpha: 0.8),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
