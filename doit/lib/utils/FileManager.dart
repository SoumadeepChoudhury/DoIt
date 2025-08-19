import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileManager {
  static FileManager? _instance;

  FileManager._internal();

  static FileManager get instance {
    _instance ??= FileManager._internal();
    return _instance!;
  }

  //Get Storage Directory
  Future<String?> getDirectoryPath() {
    return getExternalStorageDirectory().then((resp) => resp?.path.toString());
  }

  // Create a user's settings file
  Future<File?> createUserSettingsFile() async {
    final dir = await getDirectoryPath();
    if (dir != null) {
      final file = File('$dir/user_settings.doit');
      return file.create();
    }
    return null;
  }

  // Add the settings: enable notifications & default reminder time
  Future<void> addUserSettings(Map<String, dynamic> settings) async {
    final file = await createUserSettingsFile();
    if (file != null) {
      await file.writeAsString(jsonEncode(settings));
    }
  }

  //Get the settings from the file
  Future<Map<String, dynamic>?> getUserSettings() async {
    final file = await createUserSettingsFile();
    if (file != null && await file.exists()) {
      final contents = await file.readAsString();
      return Map<String, dynamic>.from(json.decode(contents));
    }
    return null;
  }
}
