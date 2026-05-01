import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:doit/components/DownloadProgress.dart';
import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

String? _activeUpdateDownloadTaskId;
Timer? _updateDownloadWatcher;
bool _isUpdateDownloadDialogVisible = false;

String generateRewardName(int level) {
  final prefixes = [
    "Shiny",
    "Golden",
    "Mystic",
    "Radiant",
    "Enchanted",
    "Sacred",
    "Celestial",
    "Eternal"
  ];
  final nouns = [
    "Sprout",
    "Leaf",
    "Bloom",
    "Ribbon",
    "Crown",
    "Crystal",
    "Flame",
    "Star",
    "Stone",
    "Charm"
  ];
  final suffixes = ["Badge", "Medal", "Trophy", "Seal", "Amulet", "Emblem"];

  // Pick prefix/noun/suffix based on level
  final prefix = prefixes[level % prefixes.length];
  final noun = nouns[level % nouns.length];

  // Add suffix only on higher levels (optional variety)
  if (level > 10) {
    final suffix = suffixes[level % suffixes.length];
    return "$prefix $noun $suffix";
  } else {
    return "$prefix $noun";
  }
}

Future<String> getLevelMessage() async {
  AppProvider appProvider = AppProvider(null);
  final level = await getCurrentLevel(appProvider);
  final percent = await getPercentage(appProvider, level);

  String status;

  if (percent == 100) {
    status = "Level Completed 🎉";
  } else if (percent > 90) {
    status = "Final Push ⚡";
  } else if (percent > 70) {
    status = "About to Level Up 🔥";
  } else if (percent > 50) {
    status = "Almost There ✨";
  } else if (percent > 20) {
    status = "Keep Going 💪";
  } else {
    status = "Good Start 🚀";
  }

  return "Level $level: $status";
}

int getMaxNoOfCompletedTask(int level) {
  int val = 0;
  for (int i = 1; i <= level; i++) {
    val += (i * 100);
  }
  return val;
}

int getCompletedTaskCount(List<Task> tasks) {
  return tasks.where((task) => task.isDone).length;
}

int compareVersionCodes(String latestVersion, String currentVersion) {
  final latestParts = latestVersion.split(".").map(int.tryParse).toList();
  final currentParts = currentVersion.split(".").map(int.tryParse).toList();
  final maxLength = latestParts.length > currentParts.length
      ? latestParts.length
      : currentParts.length;

  for (var i = 0; i < maxLength; i++) {
    final latest = i < latestParts.length ? latestParts[i] ?? 0 : 0;
    final current = i < currentParts.length ? currentParts[i] ?? 0 : 0;

    if (latest != current) {
      return latest.compareTo(current);
    }
  }

  return 0;
}

Future<int> getCurrentLevel(AppProvider appProvider) async {
  // int completedTasks =
  // getCompletedTaskCount(tasks); // get count from the new table
  // fetch the count from the database
  int completedTasks = await appProvider.getCompletedTasksCount();
  int level = 0;
  int i = 1;
  while (level == 0) {
    if (completedTasks < getMaxNoOfCompletedTask(i)) {
      level = i;
    }
    i++;
  }
  return level;
}

Future<int> getPercentage(AppProvider appProvider, int level) async {
  int completedTasks = await appProvider.getCompletedTasksCount();

  int maxTasksUpperLevel = getMaxNoOfCompletedTask(level);
  int maxTaskLowerLevel = getMaxNoOfCompletedTask(level - 1);
  return ((completedTasks - maxTaskLowerLevel) /
          (maxTasksUpperLevel - maxTaskLowerLevel) *
          100)
      .toInt();
}

void checkUpdate(BuildContext context) async {
  if (!context.mounted) return;

  try {
    final response = await http.get(
        Uri.parse(
            "https://api.github.com/repos/SoumadeepChoudhury/DoIt/releases"),
        headers: {"User-Agent": "Flutter-DoIt-App"});

    String url = "";
    String latest_version_code = "";
    if (response.statusCode == 200) {
      // var data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      var data = jsonDecode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        var latestRelease = data[0] as Map<String, dynamic>;
        final tagName = latestRelease["tag_name"].toString();
        latest_version_code =
            tagName.startsWith("v") ? tagName.substring(1) : tagName;
        print("LVC: " + latest_version_code);
        String path = (await getExternalStorageDirectory())?.path ??
            "/storage/emulated/0/Download";
        await _deleteOldUpdateApks(path, latest_version_code);
        File file = File("$path/app-release-v$latest_version_code.apk");

        final info = await PackageInfo.fromPlatform();
        String current_version_code = info.version;
        print("CVC: " + current_version_code);

        //Compare the two version code and if the latest is greater then print it.
        if (compareVersionCodes(latest_version_code, current_version_code) >
            0) {
          final assets = latestRelease["assets"] as List<dynamic>? ?? [];
          final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
                (asset) => asset?["name"].toString().endsWith(".apk") ?? false,
                orElse: () => null,
              );
          url = apkAsset?["browser_download_url"]?.toString() ??
              "https://github.com/SoumadeepChoudhury/DoIt/releases/download/v$latest_version_code/app-release.apk";

          final existingLatestDownload =
              await _getExistingUpdateDownloadTask(latest_version_code);
          if (existingLatestDownload != null) {
            if (existingLatestDownload.status == DownloadTaskStatus.complete &&
                await file.exists()) {
              _activeUpdateDownloadTaskId = existingLatestDownload.taskId;
              if (!context.mounted) return;
              _showUpdateDownloadDialog(context, existingLatestDownload.taskId);
              return;
            }

            if (existingLatestDownload.status == DownloadTaskStatus.running ||
                existingLatestDownload.status == DownloadTaskStatus.enqueued ||
                existingLatestDownload.status == DownloadTaskStatus.paused) {
              _activeUpdateDownloadTaskId = existingLatestDownload.taskId;
              if (!context.mounted) return;
              _watchUpdateDownload(context, existingLatestDownload.taskId);
              _showUpdateDownloadDialog(context, existingLatestDownload.taskId);
              return;
            }
          }

          if (await file.exists()) {
            try {
              await file.delete();
            } on FileSystemException catch (_) {
              print("Can't delete the file");
            }
          }

          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.7),
            builder: (context) => Dialog(
              backgroundColor: surfaceColor.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.system_update,
                            color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "Update Available",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Message
                    Text(
                      "A new version of the app is available with improvements and bug fixes.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Version info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "Version $latest_version_code",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            "LATER",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close the dialog
                            String? taskId = await downloadAndInstallAPK(
                                url, latest_version_code, context);
                            if (!context.mounted) return;
                            // Show download started dialog
                            _showUpdateDownloadDialog(context, taskId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "DOWNLOAD NOW",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
  } catch (e) {
    print("Failed to connect to GitHub API. Check your internet connection.");
    return;
  }
}

Future<String?> downloadAndInstallAPK(
    String apkUrl, String version, BuildContext context) async {
  final savePath = (await getExternalStorageDirectory())?.path ??
      (await getApplicationDocumentsDirectory()).path;
  final fileName = "app-release-v$version.apk";
  final notificationPermission = await Permission.notification.request();

  try {
    // Track download completion
    FlutterDownloader.registerCallback(MyDownloader.downloadCallback);

    // Start downloading
    String? taskId = await FlutterDownloader.enqueue(
      url: apkUrl,
      savedDir: savePath,
      fileName: fileName,
      showNotification: notificationPermission.isGranted,
      openFileFromNotification: notificationPermission.isGranted,
    );

    _activeUpdateDownloadTaskId = taskId;
    if (taskId != null && context.mounted) {
      _watchUpdateDownload(context, taskId);
    }

    return taskId;
  } catch (e) {
    print("Failed to start update download.");
    return null;
  }
}

void _showUpdateDownloadDialog(BuildContext context, String? taskId) {
  if (!context.mounted || taskId == null || _isUpdateDownloadDialogVisible) {
    return;
  }

  _isUpdateDownloadDialogVisible = true;
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    barrierDismissible: true,
    builder: (context) => DownloadProgressDialog(taskId: taskId),
  ).whenComplete(() {
    _isUpdateDownloadDialogVisible = false;
  });
}

void _watchUpdateDownload(BuildContext context, String taskId) {
  _updateDownloadWatcher?.cancel();
  _updateDownloadWatcher =
      Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (!context.mounted) {
      timer.cancel();
      return;
    }

    final tasks = await FlutterDownloader.loadTasks();
    final task = tasks?.cast<DownloadTask?>().firstWhere(
          (task) => task?.taskId == taskId,
          orElse: () => null,
        );

    if (!context.mounted || task == null) {
      if (!context.mounted) timer.cancel();
      return;
    }

    if (task.status == DownloadTaskStatus.complete) {
      timer.cancel();
      _activeUpdateDownloadTaskId = task.taskId;
      _showUpdateDownloadDialog(context, task.taskId);
      return;
    }

    if (task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.canceled) {
      timer.cancel();
      if (_activeUpdateDownloadTaskId == task.taskId) {
        _activeUpdateDownloadTaskId = null;
      }
    }
  });
}

Future<DownloadTask?> _getExistingUpdateDownloadTask(String version) async {
  final tasks = await FlutterDownloader.loadTasks();
  final fileName = 'app-release-v$version.apk';
  final matchingTasks = tasks
          ?.where((task) => task.filename == fileName)
          .toList()
          .reversed
          .toList() ??
      [];

  for (final task in matchingTasks) {
    if (task.status == DownloadTaskStatus.running ||
        task.status == DownloadTaskStatus.enqueued ||
        task.status == DownloadTaskStatus.paused) {
      return task;
    }
  }

  for (final task in matchingTasks) {
    if (task.status == DownloadTaskStatus.complete) {
      return task;
    }
  }

  return matchingTasks.isEmpty ? null : matchingTasks.first;
}

Future<void> _deleteOldUpdateApks(
    String directoryPath, String latestVersion) async {
  final directory = Directory(directoryPath);
  if (!await directory.exists()) return;

  final latestFileName = 'app-release-v$latestVersion.apk';
  await for (final entity in directory.list()) {
    if (entity is! File) continue;

    final fileName =
        entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
    final isUpdateApk =
        fileName.startsWith('app-release-v') && fileName.endsWith('.apk');
    if (!isUpdateApk || fileName == latestFileName) continue;

    try {
      await entity.delete();
    } on FileSystemException catch (_) {
      print("Can't delete old update file");
    }
  }
}

class MyDownloader {
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) async {
    print("$status -> $progress");
    if (progress == 100) {
      print("Downlaod completed");
      // String? filePath = await getDownloadPath();
      // print(filePath);
      // if (filePath != null) {
      // File file = File(
      //     "/storage/emulated/0/Android/data/com.example.xpens-debug/files/");
      // try {
      //   OpenFilex.open(file.path);
      // } catch (e) {
      //   print("Can't open file");
      // }
      // }
    }
  }
}
