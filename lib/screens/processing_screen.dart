import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:compress_pdf_redpdf/screens/success_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final Future<SuccessScreenArgs> Function(BuildContext context) processTask;
  final bool isPdf;
  final String title;

  const ProcessingScreen({
    super.key,
    required this.processTask,
    required this.isPdf,
    required this.title,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      final result = await widget.processTask(context);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/success',
        arguments: result,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = widget.isPdf
        ? (isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight)
        : (isDark ? AppThemeColors.imageDark : AppThemeColors.imageLight);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _error == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colors.primary),
                      const SizedBox(height: 24),
                      Text(
                        "Please wait...\nThis might take a moment.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        "Compression Failed",
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Go Back", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
