import 'dart:io';

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'pdf_view_screen.dart';

class SuccessScreenArgs {
  final String title;
  final String subtitle;
  final String filePath;
  final int? beforeBytes;
  final int? afterBytes;
  final bool isPdf;

  const SuccessScreenArgs({
    required this.title,
    required this.subtitle,
    required this.filePath,
    required this.isPdf,
    this.beforeBytes,
    this.afterBytes,
  });
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  static String _formatBytes(int bytes) {
    const kb = 1024.0;
    const mb = kb * 1024.0;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as SuccessScreenArgs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = args.isPdf
        ? (isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight)
        : (isDark ? AppThemeColors.imageDark : AppThemeColors.imageLight);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: colors.text),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.08),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(6, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 86,
                          width: 86,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            args.isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: colors.primary,
                            size: 46,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          args.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          args.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.text.withValues(alpha: 0.7),
                          ),
                        ),
                        if (args.beforeBytes != null &&
                            args.afterBytes != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatBytes(args.beforeBytes!),
                                  style: TextStyle(
                                    color: colors.text.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_right_alt,
                                  color: colors.primary,
                                ),
                                Text(
                                  _formatBytes(args.afterBytes!),
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (args.isPdf) ...[
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfViewScreen(
                                title: args.title,
                                path: args.filePath,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text(
                          'View PDF',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: args.isPdf
                            ? colors.primary.withValues(alpha: 0.1)
                            : colors.primary,
                        foregroundColor: args.isPdf
                            ? colors.primary
                            : Colors.white,
                        elevation: args.isPdf ? 0 : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () async {
                        final file = File(args.filePath);
                        if (!await file.exists()) return;
                        await Share.shareXFiles([XFile(args.filePath)]);
                      },
                      icon: const Icon(Icons.ios_share),
                      label: const Text(
                        'Share / Export',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(
                          color: colors.primary.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
