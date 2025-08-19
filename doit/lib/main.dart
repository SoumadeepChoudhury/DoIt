// main.dart
import 'package:doit/components/HistoryPage.dart';
import 'package:doit/components/HomePage.dart';
import 'package:doit/components/LevelsPage.dart';
import 'package:doit/components/SettingsPage.dart';
import 'package:doit/utils/AssistingFunctions.dart';
import 'package:doit/utils/CustomBottomNavBar.dart';
import 'package:doit/utils/Notifications.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Notifications().initNotificationSettings();
  requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentBottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => AppProvider())],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Elegant Task Manager',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark().copyWith(
              primary: const Color(0xFF81C784),
              secondary: const Color(0xFFFFD740),
            ),
          ),
          home: Scaffold(
              extendBody: true,
              body: Builder(
                builder: (context) {
                  switch (_currentBottomNavIndex) {
                    case 0:
                      return const HomePage();
                    case 1:
                      return const HistoryPage();
                    case 2:
                      return const LevelsPage();
                    case 3:
                      return const SettingsPage();
                    default:
                      return const HomePage();
                  }
                },
              ),
              bottomNavigationBar: // Floating Navigation Bar
                  CustomFloatingNavBar(
                currentIndex: _currentBottomNavIndex,
                onTap: (index) {
                  setState(() {
                    _currentBottomNavIndex = index;
                  });
                },
              ))),
    );
  }
}
