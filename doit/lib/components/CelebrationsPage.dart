import 'package:doit/utils/AssistingFunctions.dart';
import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

import 'package:provider/provider.dart';

//DUCK: https://lottie.host/c42faa33-3500-4c53-b448-775f6d13e720/11bf2BfmhB.json
//Trophie: https://lottie.host/45b08f56-4196-458b-ad95-f9d7fdb304b3/K4PXomvhwH.json
/*
Image.asset(
        "assets/images/duckie.gif",
        repeat: ImageRepeat.noRepeat,
    ),
*/

class CelebrationPage extends StatefulWidget {
  const CelebrationPage({super.key});

  @override
  State<CelebrationPage> createState() => _CelebrationPageState();
}

class _CelebrationPageState extends State<CelebrationPage> {
  late Timer _timer;
  double _scale = 0.0;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Start animation
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _scale = 1.0;
        _opacity = 1.0;
      });
    });

    // Auto-navigate after 4 seconds
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
            child: Stack(
              children: [
                // Subtle particle background
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.2,
                    child: Lottie.asset(
                      'assets/json/Trophy.json',
                      repeat: true,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Main celebration animation
                Center(
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    child: Lottie.asset(
                      'assets/json/Trophy.json',
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.width * 0.9,
                      repeat: true,
                    ),
                  ),
                ),

                // Message with fade animation
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        Text(
                          'LEVEL UP!',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All tasks completed successfully',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${getCurrentLevel(appProvider.tasks) + 1} Unlocked',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Premium badge at top
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 1500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: surfaceColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: primaryColor, size: 25),
                            const SizedBox(width: 12),
                            Text(
                              'Total Tasks Completed: ${getCompletedTaskCount(appProvider.tasks)}',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
