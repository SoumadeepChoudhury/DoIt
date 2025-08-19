import 'dart:convert';
import 'dart:io';

import 'package:doit/components/DownloadProgress.dart';
import 'package:doit/models/TaskModel.dart';
import 'package:doit/utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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

String getLevelMessage(List<Task> tasks) {
  int level = getCurrentLevel(tasks);
  int percent = getPercentage(level, tasks);

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

int getCurrentLevel(List<Task> tasks) {
  int completedTasks = getCompletedTaskCount(tasks);
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

int getPercentage(int level, List<Task> tasks) {
  int completedTasks = tasks.where((task) => task.isDone).length;
  int maxTasksUpperLevel = getMaxNoOfCompletedTask(level);
  int maxTaskLowerLevel = getMaxNoOfCompletedTask(level - 1);
  return ((completedTasks - maxTaskLowerLevel) /
          (maxTasksUpperLevel - maxTaskLowerLevel) *
          100)
      .toInt();
}

void checkUpdate(BuildContext context) async {
  final response = await http.get(Uri.parse(
      "https://api.github.com/repos/SoumadeepChoudhury/DoIt/releases"));
  String url = "";
  String latest_version_code = "";
  if (response.statusCode == 200) {
    var data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    if (data.isNotEmpty) {
      latest_version_code = (data[0]["tag_name"]).substring(1);
      //Deleteing existing file
      String path = (await getExternalStorageDirectory())?.path ??
          "/storage/emulated/0/Download";
      File file = File("$path/app-release-v$latest_version_code.apk");
      if (await file.exists()) {
        try {
          await file.delete();
        } on FileSystemException catch (_) {
          print("Can't delete the file");
        }
      }

      final info = await PackageInfo.fromPlatform();
      String current_version_code = info.version;

      //Compare the two version code and if the latest is greater then print it.
      if (latest_version_code.compareTo(current_version_code) > 0) {
        url =
            "https://github.com/SoumadeepChoudhury/DoIt/releases/download/v$latest_version_code/app-release.apk";
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.system_update, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        "Update Available",
                        style: GoogleFonts.nunitoSans(
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
                    style: GoogleFonts.nunitoSans(
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
                        Icon(Icons.info_outline, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "Version $latest_version_code",
                          style: GoogleFonts.nunitoSans(
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
                          style: GoogleFonts.nunitoSans(
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

                          // Show download started dialog
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.7),
                            builder: (context) =>
                                DownloadProgressDialog(taskId: taskId),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "DOWNLOAD NOW",
                          style: GoogleFonts.nunitoSans(
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
}

Future<String?> downloadAndInstallAPK(
    String apkUrl, String version, BuildContext context) async {
  // Request storage permission
  if (await Permission.manageExternalStorage.request().isGranted ||
      await Permission.storage.request().isGranted) {
    final savePath = (await getExternalStorageDirectory())?.path ??
        "/storage/emulated/0/Download";
    final fileName = "app-release-v$version.apk";

    if (await Permission.notification.request().isGranted) {
      // Track download completion
      FlutterDownloader.registerCallback(MyDownloader.downloadCallback);

      // Start downloading
      String? taskId = await FlutterDownloader.enqueue(
        url: apkUrl,
        savedDir: savePath,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );

      return taskId;
    }
  } else {
    return null;
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
