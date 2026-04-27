import 'dart:io';

import 'package:compress_pdf_redpdf/screens/image_com_screen.dart';
import 'package:compress_pdf_redpdf/screens/pdf_com_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pdfColor = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;
    final imgColor = isDark ? AppThemeColors.imageDark : AppThemeColors.imageLight;

    return Scaffold(
      backgroundColor: pdfColor.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    subtitle: "Reduce PDF file size easily while keeping quality",
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
                    subtitle: "Optimize JPG, PNG, and WebP without quality loss",
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
        builder: (context) => CompressPdfScreen(
          initialFile: file,
          initialBytes: bytes,
        ),
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
        builder: (context) => CompressImageScreen(
          initialFile: file,
          initialBytes: bytes,
        ),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 110, maxHeight: 150),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 5,
            offset: Offset(5, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 40),
          ),

          const SizedBox(width: 12),

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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),

          Icon(Icons.arrow_forward_ios, size: 16, color: primary),
        ],
      ),
    );
  }
}
