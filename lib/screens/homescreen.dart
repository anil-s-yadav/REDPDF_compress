import 'dart:io';

import 'package:compress_pdf_redpdf/screens/image_com_screen.dart';
import 'package:compress_pdf_redpdf/screens/pdf_com_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pdfColor = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;
    final imgColor = isDark
        ? AppThemeColors.imageDark
        : AppThemeColors.imageLight;

    return Scaffold(
      backgroundColor: pdfColor.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RedPDF Compressor",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: pdfColor.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                /// CARD 1 - Compress PDF
                GestureDetector(
                  onTap: () => _pickPdfAndNavigate(context),
                  child: _featureCard(
                    context,
                    title: "Compress PDF",
                    subtitle:
                        "Reduce PDF file size easily while keeping best quality.",
                    icon: Icons.picture_as_pdf_outlined,
                    primary: pdfColor.primary,
                    card: pdfColor.card,
                    text: pdfColor.text,
                    subtitleColor: pdfColor.text,
                  ),
                ),

                /// CARD 2 - Compress Image
                GestureDetector(
                  onTap: () => _pickImageAndNavigate(context),
                  child: _featureCard(
                    context,
                    title: "Compress Image",
                    subtitle:
                        "Optimize JPG, PNG, and WebP without quality loss in KB.",
                    icon: Icons.image_outlined,
                    primary: imgColor.primary,
                    card: imgColor.card,
                    text: imgColor.text,
                    subtitleColor: imgColor.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdfAndNavigate(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;

    final file = File(path);
    final bytes = await file.length();

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CompressPdfScreen(initialFile: file, initialBytes: bytes),
      ),
    );
  }

  Future<void> _pickImageAndNavigate(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;

    final file = File(path);
    final bytes = await file.length();

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CompressImageScreen(initialFile: file, initialBytes: bytes),
      ),
    );
  }

  /// 🔹 Feature Card
  Widget _featureCard(
    BuildContext cnt, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primary,
    required Color card,
    required Color text,
    required Color subtitleColor,
  }) {
    final isDark = Theme.of(cnt).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 110, maxHeight: 150),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withAlpha(isDark ? 30 : 15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(isDark ? 20 : 25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withAlpha(isDark ? 40 : 8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        spacing: 15,
        children: [
          /// Icon Box — gradient background
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withAlpha(30),
                  primary.withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: primary.withAlpha(25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: primary, size: 36),
          ),

          /// Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor.withAlpha(140),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primary),
          ),
        ],
      ),
    );
  }
}
