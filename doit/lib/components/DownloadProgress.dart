import 'dart:async';

import 'package:doit/utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String? taskId;

  const DownloadProgressDialog({super.key, required this.taskId});

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  DownloadTaskStatus? _status;
  Timer? _progressTimer;
  bool _isOpeningInstaller = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskId == null) {
      _status = DownloadTaskStatus.failed;
    } else {
      _startProgressTracking();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressTracking() {
    _refreshProgress();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _refreshProgress();
    });
  }

  Future<void> _refreshProgress() async {
    if (widget.taskId == null) return;

    final tasks = await FlutterDownloader.loadTasks();
    final task = tasks?.cast<DownloadTask?>().firstWhere(
          (task) => task?.taskId == widget.taskId,
          orElse: () => null,
        );

    if (!mounted || task == null) return;

    final progress = task.progress < 0 ? 0 : task.progress.clamp(0, 100);
    setState(() {
      _progress = progress / 100;
      _status = task.status;
    });

    if (task.status == DownloadTaskStatus.complete ||
        task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.canceled) {
      _progressTimer?.cancel();
    }
  }

  Future<void> _openInstaller() async {
    if (widget.taskId == null || _isOpeningInstaller) return;

    setState(() {
      _isOpeningInstaller = true;
    });

    try {
      final installPermission =
          await Permission.requestInstallPackages.request();
      if (!installPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Please allow app installs to continue the update."),
            ),
          );
        }
        return;
      }

      await FlutterDownloader.open(taskId: widget.taskId!);
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningInstaller = false;
        });
      }
    }
  }

  String get _statusText {
    if (_status == DownloadTaskStatus.complete) return "Download complete";
    if (_status == DownloadTaskStatus.failed) return "Download failed";
    if (_status == DownloadTaskStatus.canceled) return "Download canceled";
    if (_status == DownloadTaskStatus.paused) return "Download paused";
    if (_status == DownloadTaskStatus.enqueued) return "Waiting to start";
    return "Downloading update";
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _status == DownloadTaskStatus.complete;
    final isFinished = _status == DownloadTaskStatus.complete ||
        _status == DownloadTaskStatus.failed ||
        _status == DownloadTaskStatus.canceled;
    final actionColor = isComplete
        ? primaryColor
        : isFinished
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.red.withValues(alpha: 0.8);
    final actionTextColor = isComplete ? Colors.black : textPrimary;

    return Dialog(
      backgroundColor: surfaceColor.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A3A2F).withValues(alpha: 0.9),
              const Color(0xFF0F1A2F).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: widget.taskId == null && !isFinished ? null : _progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "${(_progress * 100).toStringAsFixed(0)}% Complete",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isComplete
                  ? "Download complete. Tap Install Update to open the Android installer."
                  : _status == DownloadTaskStatus.failed
                      ? "The update download could not be completed. Please try again."
                      : _status == DownloadTaskStatus.canceled
                          ? "Download canceled."
                          : "Please keep the app open while the update downloads.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isOpeningInstaller
                  ? null
                  : isComplete
                      ? _openInstaller
                      : isFinished
                          ? () => Navigator.pop(context)
                          : () {
                              if (widget.taskId != null) {
                                FlutterDownloader.cancel(
                                    taskId: widget.taskId!);
                              }
                              Navigator.pop(context);
                            },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.45),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isOpeningInstaller
                    ? "OPENING..."
                    : isComplete
                        ? "INSTALL UPDATE"
                        : isFinished
                            ? "CLOSE"
                            : "CANCEL DOWNLOAD",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: actionTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
