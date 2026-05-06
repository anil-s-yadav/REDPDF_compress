import 'dart:io';

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'pdf_view_screen.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

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

  Future<void> _openPdf(BuildContext context, String path, String title) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF file could not be found.")),
        );
      }
      return;
    }

    bool isProtected = false;
    try {
      final protectionInfo = await PdfManipulator().pdfValidityAndProtection(
        params: PDFValidityAndProtectionParams(pdfPath: path),
      );
      if (protectionInfo != null && 
          (protectionInfo.isOpenPasswordProtected == true || protectionInfo.isOwnerPasswordProtected == true)) {
        isProtected = true;
      }
    } catch (e) {
      //
    }

    String? password;
    if (isProtected) {
      password = await _showPasswordDialog(context);
      if (password == null || password.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password is required to view this PDF.')),
          );
        }
        return;
      }
    }
    
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewScreen(
            title: title,
            path: path,
            password: password,
          ),
        ),
      );
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    String? password;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Password Protected'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter PDF password to view',
            ),
            onChanged: (value) {
              password = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Unlock'),
              onPressed: () => Navigator.of(context).pop(password),
            ),
          ],
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    const kb = 1024.0;
    const mb = kb * 1024.0;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Widget _buildSizeRow(SuccessScreenArgs args, AppColors colors) {
    if (args.beforeBytes == null || args.afterBytes == null) {
      return const SizedBox.shrink();
    }
    final saved = args.beforeBytes! - args.afterBytes!;
    final pct = saved * 100 ~/ args.beforeBytes!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            _formatBytes(args.beforeBytes!),
            style: TextStyle(
              color: colors.text.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, color: colors.primary, size: 16),
          ),
          Text(
            _formatBytes(args.afterBytes!),
            style: TextStyle(
              color: Colors.green,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '-$pct%',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(
    BuildContext context,
    SuccessScreenArgs args,
    AppColors colors,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _openPdf(context, args.filePath, args.title);
          },
          child: ListTile(
            contentPadding: EdgeInsets.all(10),
            leading: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: colors.primary,
                size: 38,
              ),
            ),
            title: Text(
              args.title,
              // textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            // const SizedBox(width: 4),
            subtitle: Text(
              args.subtitle,
              // textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ),

        // const SizedBox(height: 12),
        if (args.beforeBytes != null && args.afterBytes != null) ...[
          const SizedBox(height: 12),
          _buildSizeRow(args, colors),
        ],
      ],
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    SuccessScreenArgs args,
    AppColors colors,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // Thumbnail
            GestureDetector(
              onTap: () async {
                final file = File(args.filePath);
                if (!file.existsSync()) return;
                final result = await OpenFilex.open(args.filePath);
                if (result.type != ResultType.done && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.message.isNotEmpty
                            ? result.message
                            : 'Could not open file.',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.5),
                  child: Image.file(File(args.filePath), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    args.title,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    args.subtitle,
                    style: TextStyle(
                      color: colors.text.withValues(alpha: 0.6),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap thumbnail to open',
                    style: TextStyle(
                      color: colors.primary.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (args.beforeBytes != null && args.afterBytes != null) ...[
          const SizedBox(height: 20),
          _buildSizeRow(args, colors),
        ],
      ],
    );
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
      appBar: AppBar(
        title: Text(
          args.subtitle,
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.bg,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row(
                  //   children: [
                  //     IconButton(
                  //       onPressed: () => Navigator.pop(context),
                  //       icon: Icon(Icons.arrow_back, color: colors.text),
                  //     ),
                  //     const Spacer(),
                  //   ],
                  // ),
                  // const SizedBox(height: 10),
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
                    child: args.isPdf
                        ? _buildPdfCard(context, args, colors)
                        : _buildImageCard(context, args, colors),
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
                          _openPdf(context, args.filePath, args.title);
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text(
                          'View PDF',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
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
                        onPressed: () async {
                          final file = File(args.filePath);
                          if (!file.existsSync()) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Image file could not be found.",
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          final result = await OpenFilex.open(args.filePath);
                          if (result.type != ResultType.done &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.message.isNotEmpty
                                      ? result.message
                                      : 'Could not open file.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text(
                          'Open in Gallery',
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
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        foregroundColor: colors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () async {
                        final file = File(args.filePath);
                        if (!await file.exists()) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("File not found for sharing."),
                              ),
                            );
                          }
                          return;
                        }
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
