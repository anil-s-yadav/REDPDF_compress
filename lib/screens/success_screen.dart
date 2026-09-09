import 'dart:io';

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:share_plus/share_plus.dart';

import 'pdf_view_screen.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

class SuccessScreenArgs {
  final String title;
  final String subtitle;
  final String filePath;
  final String? previewPath;
  final int? beforeBytes;
  final int? afterBytes;
  final bool isPdf;

  const SuccessScreenArgs({
    required this.title,
    required this.subtitle,
    required this.filePath,
    required this.isPdf,
    this.previewPath,
    this.beforeBytes,
    this.afterBytes,
  });
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  Future<String> _getUsablePath(SuccessScreenArgs args) async {
    // 1. Check if previewPath is a valid local file
    if (args.previewPath != null && File(args.previewPath!).existsSync()) {
      return args.previewPath!;
    }
    // 2. Check if filePath exists directly on disk
    if (!args.filePath.startsWith('content://') && File(args.filePath).existsSync()) {
      return args.filePath;
    }
    // 3. If it's a SAF content URI, copy to cache directory so OpenFilex / Share can access it
    if (args.filePath.startsWith('content://')) {
      try {
        final tempDir = await getTemporaryDirectory();
        final ext = args.isPdf ? '.pdf' : '.jpg';
        final tempPath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}$ext';
        await Saf().copyToLocalFile(args.filePath, tempPath);
        return tempPath;
      } catch (_) {}
    }
    return args.filePath;
  }

  Future<void> _openPdf(BuildContext context, SuccessScreenArgs args) async {
    final path = await _getUsablePath(args);
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
    } catch (_) {
      // fallback
    }

    String? password;
    if (isProtected) {
      if (!context.mounted) return;
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
            title: args.title,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final pct = (saved * 100 / (args.beforeBytes! > 0 ? args.beforeBytes! : 1)).round().clamp(0, 99);
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
            style: const TextStyle(
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
              style: const TextStyle(
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
          onTap: () => _openPdf(context, args),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: colors.primary,
                size: 36,
              ),
            ),
            title: Text(
              args.title,
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              args.subtitle,
              style: TextStyle(
                color: colors.text.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ),
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
    final displayPath = args.previewPath ?? args.filePath;
    final file = File(displayPath);

    return Column(
      children: [
        Row(
          children: [
            // Thumbnail
            GestureDetector(
              onTap: () async {
                final path = await _getUsablePath(args);
                final result = await OpenFilex.open(path);
                if (result.type != ResultType.done && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.message.isNotEmpty
                            ? result.message
                            : 'Could not open image file.',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.5),
                  child: file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colors.primary.withValues(alpha: 0.1),
                              child: Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  color: colors.primary,
                                  size: 36,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: colors.primary.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: colors.primary,
                              size: 36,
                            ),
                          ),
                        ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    args.subtitle,
                    style: TextStyle(
                      color: colors.text.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap thumbnail to open',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (args.beforeBytes != null && args.afterBytes != null) ...[
          const SizedBox(height: 16),
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
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
            const SizedBox(width: 8),
            Text(
              "Success",
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: colors.bg,
        elevation: 0,
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(18)
                            : colors.primary.withAlpha(22),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
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
                        onPressed: () => _openPdf(context, args),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
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
                          final path = await _getUsablePath(args);
                          final result = await OpenFilex.open(path);
                          if (result.type != ResultType.done && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.message.isNotEmpty
                                      ? result.message
                                      : 'Could not open image file.',
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
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(10)
                                  : colors.primary.withAlpha(14),
                              foregroundColor: colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colors.primary.withAlpha(isDark ? 30 : 25),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final path = await _getUsablePath(args);
                              if (!await File(path).exists()) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("File not found for sharing."),
                                    ),
                                  );
                                }
                                return;
                              }
                              await Share.shareXFiles([XFile(path)]);
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text(
                              'Share',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(10)
                                  : colors.primary.withAlpha(14),
                              foregroundColor: colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colors.primary.withAlpha(isDark ? 30 : 25),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.popUntil(context, (r) => r.isFirst),
                            icon: const Icon(Icons.home_rounded, size: 18),
                            label: const Text(
                              'Home',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
