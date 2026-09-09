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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [pdfColor.primary, pdfColor.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: pdfColor.primary.withAlpha(60),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          Row(
                            children: [
                              Text(
                                "RedPDF",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: pdfColor.text,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: pdfColor.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "COMPRESS",
                                  style: TextStyle(
                                    color: pdfColor.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ── Section Title ──
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        "Select a tool to compress",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: pdfColor.text.withAlpha(140),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    // ── CARD 1: Compress PDF ──
                    _featureCard(
                      context,
                      title: "Compress PDF",
                      subtitle:
                          "Reduce PDF file size easily with best quality.",
                      badge: "PDF",
                      tags: const ["Smart Quality", "Target Size", "Fast"],
                      icon: Icons.picture_as_pdf_rounded,
                      primary: pdfColor.primary,
                      accent: pdfColor.accent,
                      card: pdfColor.card,
                      text: pdfColor.text,
                      isDark: isDark,
                      onTap: () => _pickPdfAndNavigate(context),
                    ),

                    const SizedBox(height: 16),

                    // ── CARD 2: Compress Image ──
                    _featureCard(
                      context,
                      title: "Compress Image",
                      subtitle:
                          "Optimize & resize Image to custom dimensions & exact KB.",
                      badge: "IMAGE",
                      tags: const [
                        "Resize Dimensions",
                        "Exact KB",
                        "JPG • PNG • WebP",
                      ],
                      icon: Icons.image_rounded,
                      primary: imgColor.primary,
                      accent: imgColor.accent,
                      card: imgColor.card,
                      text: imgColor.text,
                      isDark: isDark,
                      onTap: () => _pickImageAndNavigate(context),
                    ),
                  ],
                ),
              ),
            ),

            // ── Privacy Footer pinned to bottom ──
            Padding(
              padding: const EdgeInsets.only(bottom: 14, top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: pdfColor.text.withAlpha(90),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "100% Private • Processed On-Device",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: pdfColor.text.withAlpha(90),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    required String badge,
    required List<String> tags,
    required IconData icon,
    required Color primary,
    required Color accent,
    required Color card,
    required Color text,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(18) : primary.withAlpha(22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withAlpha(isDark ? 15 : 12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 35 : 6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon container with gradient
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withAlpha(70),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: text,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: text.withAlpha(130),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha(10)
                                  : Colors.black.withAlpha(6),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: text.withAlpha(120),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(isDark ? 30 : 18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
