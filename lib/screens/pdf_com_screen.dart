import 'dart:developer';
import 'dart:io';

import 'package:compress_pdf_redpdf/providers/pdf_provider.dart';
import 'package:compress_pdf_redpdf/screens/success_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../models/compression_history_item.dart';

class CompressPdfScreen extends StatefulWidget {
  final File? initialFile;
  final int? initialBytes;

  const CompressPdfScreen({super.key, this.initialFile, this.initialBytes});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  double compressionLevel =
      0.5; // UI: 0=Low (high quality) ... 1=High (smallest file)
  File? _selectedPdf;
  int? _selectedBytes;
  bool _isWorking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPdf = widget.initialFile;
    _selectedBytes = widget.initialBytes;

    // Set default compression level from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      setState(() {
        compressionLevel = settings.numericCompressionLevel;
      });
    });
  }

  double _estimatedRatio() {
    // Heuristic for preview only.
    if (compressionLevel <= 0.34) return 0.80;
    if (compressionLevel <= 0.67) return 0.55;
    return 0.35;
  }

  String _formatBytes(int bytes) {
    const kb = 1024.0;
    const mb = kb * 1024.0;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<void> _pickPdf() async {
    setState(() {
      _error = null;
    });

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
    if (!mounted) return;
    setState(() {
      _selectedPdf = file;
      _selectedBytes = bytes;
    });
  }

  Future<void> _compress() async {
    final src = _selectedPdf;
    if (src == null) {
      setState(() => _error = 'Please select a PDF first.');
      return;
    }

    setState(() {
      _isWorking = true;
      _error = null;
    });

    final provider = context.read<PdfProvider>();

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return;
        }
        if (!status.isGranted) {
          // On Android 11+ Permission.storage might not grant write to some public folders
          // But for Downloads usually it's okay or we might need manageExternalStorage
          // Let's try to continue and see if it works, or ask for MANAGE if it's a dedicated folder.
        }
      }

      final beforeBytes = await src.length();
      final safeName = src.uri.pathSegments.last;
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();

      // Get temporary directory for initial compression
      final tempDir = await getTemporaryDirectory();

      final File? outFile = await provider.compressPdf(
        inputFile: src,
        level: compressionLevel,
        storagePath: tempDir.path,
      );

      if (outFile == null) throw Exception("Compression failed");

      final afterBytes = await outFile.length();
      
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = 'RedPdf_comp_$stamp.pdf';

      // Always copy to our app's storage location for History & SuccessScreen
      final targetDir = Directory(settings.storageLocation);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final finalPath = '${targetDir.path}/$newFileName';
      File savedFile = await outFile.copy(finalPath);

      // Use MediaStore for public storage on Android
      if (Platform.isAndroid) {
        MediaStore.appFolder = "RedPDF";
        final mediaStore = MediaStore();

        // Rename the temp file so MediaStore saves it with the correct name
        final tempRenamed = await outFile.rename('${tempDir.path}/$newFileName');

        await mediaStore.saveFile(
          tempFilePath: tempRenamed.path,
          dirType: DirType.download,
          dirName: DirName.download,
          relativePath: "RedPDF",
        );
      }

      final saved = savedFile;

      if (!mounted) return;

      context.read<HistoryProvider>().add(
        CompressionHistoryItem(
          id: saved.path,
          kind: CompressionKind.pdf,
          title: newFileName,
          sourcePath: src.path,
          outputPath: saved.path,
          sourceBytes: beforeBytes,
          outputBytes: afterBytes,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/success',
        arguments: SuccessScreenArgs(
          title: 'PDF compressed',
          subtitle: 'Saved to your device.',
          filePath: saved.path,
          isPdf: true,
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Compression failed: $e');
      log(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;

    return Scaffold(
      backgroundColor: colors.bg,
      // bottomNavigationBar: _bottomNav(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _titleSection(isDark),
              const SizedBox(height: 50),

              _fileCard(isDark),

              // const SizedBox(height: 20),
              _compressionSlider(isDark),
              const SizedBox(height: 20),

              _estimatedCard(isDark),
              const SizedBox(height: 30),
              _compressButton(),
              const SizedBox(height: 20),

              // _premiumCard(),
              const SizedBox(height: 15),

              // _securityNote(isDark),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(_error!, style: TextStyle(color: colors.text)),
                ),
              ], // end if
            ], // end children
          ), // end Column
        ), // end Center
      ), // end SafeArea
    ); // end Scaffold
  }

  Widget _titleSection(bool isDark) {
    return Column(
      children: [
        Text(
          "Compress PDF",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Optimize your documents for sharing without losing visual integrity. Professional tools for refined workflows.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _compressionSlider(bool isDark) {
    final isLow = compressionLevel <= 0.34;
    final isBalanced = compressionLevel > 0.34 && compressionLevel <= 0.67;
    final isHigh = compressionLevel > 0.67;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Compression Level",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Slider(
                value: compressionLevel,
                onChanged: (v) => setState(() => compressionLevel = v),
                activeColor: Colors.red,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "High Quality",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Text(
                    "Best Balance",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Text(
                    "Smallest File",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => compressionLevel = 0.2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isLow
                              ? (isDark ? Colors.grey.shade700 : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isLow && !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          "Low",
                          style: TextStyle(
                            color: isLow ? Colors.red : Colors.grey,
                            fontWeight: isLow ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => compressionLevel = 0.5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? (isDark ? Colors.grey.shade700 : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isBalanced && !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          "Balanced",
                          style: TextStyle(
                            color: isBalanced ? Colors.red : Colors.grey,
                            fontWeight: isBalanced ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => compressionLevel = 0.8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isHigh
                              ? (isDark ? Colors.grey.shade700 : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isHigh && !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          "High",
                          style: TextStyle(
                            color: isHigh ? Colors.red : Colors.grey,
                            fontWeight: isHigh ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fileCard(bool isDark) {
    final file = _selectedPdf;
    final name = file == null ? 'No PDF selected' : file.uri.pathSegments.last;
    final bytes = _selectedBytes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CURRENT SELECTION",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              InkWell(
                onTap: _isWorking ? null : _pickPdf,
                child: const Text(
                  "Change/Reselect",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        bytes == null
                            ? "Tap “Change/Reselect” to choose a PDF"
                            : _formatBytes(bytes),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compressButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _isWorking ? null : _compress,
        child: Text(
          _isWorking ? "Compressing…" : "Compress Now",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _estimatedCard(bool isDark) {
    final bytes = _selectedBytes;
    final estBytes = bytes == null ? null : (bytes * _estimatedRatio()).round();
    final savedPct = (bytes == null || estBytes == null || bytes == 0)
        ? null
        : (((bytes - estBytes) / bytes) * 100).clamp(0, 99.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _formatBytes(_selectedBytes!),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    estBytes == null ? "—" : "~${_formatBytes(estBytes)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estBytes == null ? "—" : "-${savedPct?.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (bytes == null || estBytes == null || bytes == 0)
                  ? 0
                  : (estBytes / bytes).clamp(0.0, 1.0),

              minHeight: 4,
              backgroundColor: isDark ? Colors.black26 : Colors.grey.shade100,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            savedPct == null
                ? "Pick a PDF to see an estimate."
                : "Reducing your file size by approximately ${savedPct.toStringAsFixed(0)}%.",
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _premiumCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFF001F3F), Color(0xFF003366)],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           "Lossless Compression",
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontWeight: FontWeight.bold,
  //             fontSize: 16,
  //           ),
  //         ),
  //         const SizedBox(height: 6),
  //         const Text(
  //           "Unlock ultra-precise compression that preserves vector clarity and metadata.",
  //           style: TextStyle(color: Colors.grey),
  //         ),
  //         const SizedBox(height: 15),
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.yellow,
  //               foregroundColor: Colors.black,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(25),
  //               ),
  //             ),
  //             onPressed: () {},
  //             child: const Text("Upgrade to Premium"),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
