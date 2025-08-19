import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/FileManager.dart';
import 'package:doit/utils/Notifications.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  FileManager fileManager = FileManager.instance;

  TimeOfDay _defaultReminderTime = const TimeOfDay(hour: 12, minute: 59);
  bool _darkModeEnabled = true;
  String _version = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  void _showTimePicker() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _defaultReminderTime,
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
    if (newTime != null) {
      setState(() {
        _defaultReminderTime = newTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
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
                    'Settings',
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: textPrimary,
                    ),
                  ),
                  centerTitle: false,
                ),

                // --- Settings Content ---
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // --- Settings Section: Notifications ---
                      _buildSectionHeader('Notifications'),
                      _buildSettingCard(
                        child: Column(
                          children: [
                            _buildToggleSetting(
                              title: 'Enable Notifications',
                              value: appProvider.isNotificationsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  appProvider.isNotificationsEnabled = value;
                                  fileManager.addUserSettings(
                                      {'isNotificationsEnabled': value});
                                  appProvider.loadSettings();
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Stop All Notifications'),
                                      content: Text(
                                          'Are you sure you want to stop all existing notifications?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Notifications()
                                                .cancelAllNotifications();
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Stop'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stop All Existing Notifications',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "All existing notifications will be stopped.",
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            textPrimary.withValues(alpha: 0.6),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Settings Section: Preferences ---
                      _buildSectionHeader('Preferences'),
                      _buildSettingCard(
                        child: Column(
                          children: [
                            _buildToggleSetting(
                              title: 'Dark Mode',
                              value: _darkModeEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _darkModeEnabled = value;
                                });
                              },
                              isDisabled: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Settings Section: About ---
                      _buildSectionHeader('About'),
                      _buildSettingCard(
                        child: Column(
                          children: [
                            _buildListTile(
                              title: 'Privacy Policy',
                              icon: Icons.lock_outline,
                              onTap: () {},
                            ),
                            const Divider(height: 1, color: Colors.white12),
                            _buildListTile(
                              title: 'Terms of Service',
                              icon: Icons.description_outlined,
                              onTap: () {},
                            ),
                            const Divider(height: 1, color: Colors.white12),
                            _buildListTile(
                              title: 'App Version',
                              subtitle: _version,
                              icon: Icons.info_outline,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      // const SizedBox(height: 40),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(
                    height: 80,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    bool isDisabled = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Switch(
          value: value,
          onChanged: isDisabled ? null : onChanged,
          activeColor: primaryColor,
          activeTrackColor: primaryColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  // Widget _buildTimeSetting() {
  //   return GestureDetector(
  //     onTap: _showTimePicker,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Default Reminder Time',
  //               style: GoogleFonts.nunitoSans(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: textPrimary,
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               'Set the default time for new tasks',
  //               style: GoogleFonts.nunitoSans(
  //                 fontSize: 11,
  //                 color: textPrimary.withValues(alpha: 0.6),
  //               ),
  //             ),
  //           ],
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //           decoration: BoxDecoration(
  //             color: accentColor.withValues(alpha: 0.2),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Text(
  //             _defaultReminderTime.format(context),
  //             style: GoogleFonts.nunitoSans(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w700,
  //               color: primaryColor,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: textPrimary.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
      onTap: onTap,
    );
  }
}
