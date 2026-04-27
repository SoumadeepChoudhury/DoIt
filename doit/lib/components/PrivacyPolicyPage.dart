import 'package:doit/utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // Replace with your actual GitHub Raw URL
  final String githubUrl =
      "https://raw.githubusercontent.com/SoumadeepChoudhury/DoIt/refs/heads/main/doit/assets/documents/privacy_policy.md";

  late Future<String> _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = fetchPolicy();
  }

  Future<String> fetchPolicy() async {
    try {
      final response = await http.get(Uri.parse(githubUrl));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
            "Failed to load policy (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Could not connect to server. Check your internet.");
    }
  }

  // Future<String> fetchPolicy() async {
  //   try {
  //     // 1. Simulate a short network delay for testing the UI/Spinner
  //     await Future.delayed(const Duration(milliseconds: 800));

  //     // 2. Load the file from your local assets
  //     final String localData =
  //         await rootBundle.loadString('assets/documents/privacypolicy.md');

  //     return localData;
  //   } catch (e) {
  //     // This will trigger your _buildErrorState() if the file is missing
  //     throw Exception("Local policy file not found in assets.");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Privacy Policy",
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w800)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.15),
              const Color(0xFF0A1A0F).withValues(alpha: 0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<String>(
            future: _policyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: primaryColor));
              } else if (snapshot.hasError) {
                return _buildErrorState();
              } else {
                return Markdown(
                  data: snapshot.data ?? "",
                  styleSheet: MarkdownStyleSheet(
                    h1: GoogleFonts.nunitoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                    h2: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryColor),
                    p: GoogleFonts.nunitoSans(
                        fontSize: 15,
                        color: textPrimary.withValues(alpha: 0.9),
                        height: 1.6),
                    listBullet: GoogleFonts.nunitoSans(color: primaryColor),
                  ),
                  padding: const EdgeInsets.all(24),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              "Unable to load policy",
              style: GoogleFonts.nunitoSans(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection and try again.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                  color: textPrimary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _policyFuture = fetchPolicy();
                });
              },
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}
