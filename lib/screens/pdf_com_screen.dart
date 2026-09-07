import 'dart:io';
import '../utils/media_store_helper.dart';

import 'package:compress_pdf_redpdf/providers/pdf_provider.dart';
import 'package:compress_pdf_redpdf/screens/success_screen.dart';
import 'package:compress_pdf_redpdf/screens/processing_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../models/compression_history_item.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

class CompressPdfScreen extends StatefulWidget {
  final File? initialFile;
  final int? initialBytes;

  const CompressPdfScreen({super.key, this.initialFile, this.initialBytes});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen>
    with SingleTickerProviderStateMixin {
  double compressionLevel =
      0.5; // UI: 0=Low (high quality) ... 1=High (smallest file)
  bool _useTargetSize = false;
  final TextEditingController _targetSizeCtrl = TextEditingController();
  final TextEditingController _outputNameCtrl = TextEditingController();
  String _targetSizeUnit = 'KB';
  late TabController _modeTabController;
  BoxDecoration? _tabIndicator;
  Color? _tabIndicatorColor;
  Widget? _cachedModeToggleWidget;

  File? _selectedPdf;
  int? _selectedBytes;
  String? _error;

  @override
  void dispose() {
    _modeTabController.dispose();
    _targetSizeCtrl.dispose();
    _outputNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedPdf = widget.initialFile;
    _selectedBytes = widget.initialBytes;

    _modeTabController = TabController(length: 2, vsync: this);
    _modeTabController.addListener(() {
      if (!_modeTabController.indexIsChanging) {
        setState(() => _useTargetSize = _modeTabController.index == 1);
      }
    });

    // Set default compression level from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      setState(() {
        compressionLevel = settings.numericCompressionLevel;
      });
    });
  }

  double _estimatedRatio() {
    if (_useTargetSize &&
        _targetSizeCtrl.text.isNotEmpty &&
        _selectedBytes != null &&
        _selectedBytes! > 0) {
      double target = double.tryParse(_targetSizeCtrl.text) ?? 0;
      if (target > 0) {
        double targetBytes =
            target * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024);
        double ratio = targetBytes / _selectedBytes!;
        return ratio.clamp(0.01, 0.99);
      }
    }
    return 0.50 - (compressionLevel * 0.30);
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

  Future<String?> _showPasswordDialog() async {
    String? password;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Password Protected'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter PDF password to unlock',
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

  Future<void> _compress() async {
    final src = _selectedPdf;
    if (src == null) {
      setState(() => _error = 'Please select a PDF first.');
      return;
    }

    setState(() {
      _error = null;
    });

    bool isProtected = false;
    String? userPassword;
    File fileToCompress = src;

    try {
      final protectionInfo = await PdfManipulator().pdfValidityAndProtection(
        params: PDFValidityAndProtectionParams(pdfPath: src.path),
      );
      if (protectionInfo != null &&
          (protectionInfo.isOpenPasswordProtected == true ||
              protectionInfo.isOwnerPasswordProtected == true)) {
        isProtected = true;
      }
    } catch (e) {
      // fallback
    }

    if (isProtected) {
      userPassword = await _showPasswordDialog();
      if (userPassword == null || userPassword.isEmpty) {
        setState(() => _error = 'Password is required to compress this PDF.');
        return;
      }

      try {
        final unencryptedPath = await PdfManipulator().pdfDecryption(
          params: PDFDecryptionParams(
            pdfPath: src.path,
            password: userPassword,
          ),
        );
        if (unencryptedPath == null) throw Exception('Decryption failed');
        fileToCompress = File(unencryptedPath);
      } catch (e) {
        setState(() => _error = 'Incorrect password or decryption failed.');
        return;
      }
    }

    final provider = context.read<PdfProvider>();

    double actualLevel = compressionLevel;
    if (_useTargetSize &&
        _targetSizeCtrl.text.isNotEmpty &&
        _selectedBytes != null &&
        _selectedBytes! > 0) {
      double target = double.tryParse(_targetSizeCtrl.text) ?? 0;
      if (target > 0) {
        double targetBytes =
            target * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024);
        double targetRatio = targetBytes / _selectedBytes!;
        actualLevel = (0.50 - targetRatio) / 0.30;
        actualLevel = actualLevel.clamp(0.0, 1.0);
      }
    }
    final currentCompressionLevel = actualLevel;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          isPdf: true,
          title: 'Processing PDF',
          processTask: (ctx) async {
            final beforeBytes = await src.length();

            // Get temporary directory for initial compression
            final tempDir = await getTemporaryDirectory();

            File? outFile = await provider.compressPdf(
              inputFile: fileToCompress,
              level: currentCompressionLevel,
              storagePath: tempDir.path,
            );

            if (outFile == null) throw Exception("Compression failed");

            if (isProtected && userPassword != null) {
              try {
                final encryptedPath = await PdfManipulator().pdfEncryption(
                  params: PDFEncryptionParams(
                    pdfPath: outFile.path,
                    userPassword: userPassword,
                    ownerPassword: userPassword,
                    encryptionAES256: true,
                  ),
                );
                if (encryptedPath == null) throw Exception('Encryption failed');

                outFile = File(encryptedPath);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PDF compressed and locked with the original password.',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                throw Exception('Failed to re-apply password: $e');
              }
            }

            final afterBytes = await outFile.length();

            final stamp = DateTime.now().millisecondsSinceEpoch;
            String newFileName = 'RedPdf_comp_$stamp.pdf';
            if (_outputNameCtrl.text.trim().isNotEmpty) {
              String name = _outputNameCtrl.text.trim();
              if (!name.toLowerCase().endsWith('.pdf')) {
                name += '.pdf';
              }
              newFileName = name;
            }

            // Always copy to our app's storage location for History & SuccessScreen
            final savedPath = await MediaStoreHelper.saveFileToDownloads(
              tempFilePath: outFile.path,
              fileName: newFileName,
              mimeType: 'application/pdf',
            );
            
            if (savedPath == null) throw Exception("Failed to save to device storage");
            File savedFile = File(savedPath);

            final saved = savedFile;

            ctx.read<HistoryProvider>().add(
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

            return SuccessScreenArgs(
              title: 'PDF compressed',
              subtitle: 'Saved to your device.',
              filePath: saved.path,
              isPdf: true,
              beforeBytes: beforeBytes,
              afterBytes: afterBytes,
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            _appBar(colors),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  children: [
                    _fileCard(colors, isDark),
                    const SizedBox(height: 40),
                    _modeToggle(colors, isDark),
                    const SizedBox(height: 16),
                    _useTargetSize
                        ? _targetSizeInput(colors, isDark)
                        : _compressionSlider(colors, isDark),
                    const SizedBox(height: 16),
                    _outputNameInput(colors, isDark),
                    // const SizedBox(height: 20),
                    // _compressButton(colors),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _errorCard(colors),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────
  Widget _appBar(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: colors.text,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Compress PDF",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.text,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withAlpha(30),
                  colors.primary.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 22,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── File Card ──────────────────────────────────────────────────
  Widget _fileCard(AppColors colors, bool isDark) {
    final file = _selectedPdf;
    final name = file == null ? 'No PDF selected' : file.uri.pathSegments.last;
    final bytes = _selectedBytes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(isDark ? 10 : 12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        spacing: 6,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "SELECTED FILE",
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // PDF icon
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withAlpha(35),
                      colors.primary.withAlpha(18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withAlpha(25)),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: colors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bytes == null
                          ? "Tap to select a PDF"
                          : _formatBytes(bytes),
                      style: TextStyle(
                        color: colors.text.withAlpha(100),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Change button
              GestureDetector(
                onTap: _pickPdf,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          // ── Estimated size row ──
          if (_selectedBytes != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _estimatedRow(colors, isDark),
            ),
          ],
          const SizedBox(width: 14),
          Row(
            spacing: 10,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.orange),
              Text(
                "Output file may be slightly smaller or bigger.",
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estimatedRow(AppColors colors, bool isDark) {
    final bytes = _selectedBytes;
    final estBytes = bytes == null ? null : (bytes * _estimatedRatio()).round();
    final savedPct = (bytes == null || estBytes == null || bytes == 0)
        ? null
        : (((bytes - estBytes) / bytes) * 100).clamp(0, 99.9);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(6) : colors.primary.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withAlpha(isDark ? 15 : 20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: colors.primary.withAlpha(180),
          ),
          const SizedBox(width: 8),
          Text(
            bytes == null ? "0 B" : _formatBytes(bytes),
            style: TextStyle(
              color: colors.text.withAlpha(120),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: colors.primary.withAlpha(100),
            ),
          ),
          Text(
            estBytes == null ? "—" : "~${_formatBytes(estBytes)}",
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (savedPct != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "-${savedPct.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Mode Toggle ────────────────────────────────────────────────
  BoxDecoration _getTabIndicator(AppColors colors) {
    if (_tabIndicator != null && _tabIndicatorColor == colors.primary) {
      return _tabIndicator!;
    }
    _tabIndicatorColor = colors.primary;
    _tabIndicator = BoxDecoration(
      color: colors.primary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: colors.primary.withAlpha(60),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
    return _tabIndicator!;
  }

  Widget _modeToggle(AppColors colors, bool isDark) {
    if (_cachedModeToggleWidget != null &&
        _tabIndicatorColor == colors.primary) {
      return _cachedModeToggleWidget!;
    }

    _cachedModeToggleWidget = Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _modeTabController,
        indicator: _getTabIndicator(colors),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: colors.text.withAlpha(120),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded, size: 18),
                SizedBox(width: 8),
                Text("By Level"),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.crop_free_rounded, size: 18),
                SizedBox(width: 8),
                Text("Target Size"),
              ],
            ),
          ),
        ],
      ),
    );

    return _cachedModeToggleWidget!;
  }

  // ─── Compression Slider ─────────────────────────────────────────
  Widget _compressionSlider(AppColors colors, bool isDark) {
    final isLow = compressionLevel <= 0.34;
    final isBalanced = compressionLevel > 0.34 && compressionLevel <= 0.67;
    final isHigh = compressionLevel > 0.67;

    String levelLabel = isLow
        ? 'Low'
        : isBalanced
        ? 'Balanced'
        : 'High';
    String levelDesc = isLow
        ? 'Best quality, larger file'
        : isBalanced
        ? 'Good balance of size & quality'
        : 'Smallest file, lower quality';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Compression Level",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  levelLabel,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            levelDesc,
            style: TextStyle(color: colors.text.withAlpha(100), fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.primary.withAlpha(30),
              thumbColor: colors.primary,
              overlayColor: colors.primary.withAlpha(30),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: compressionLevel,
              onChanged: (v) => setState(() => compressionLevel = v),
            ),
          ),

          // Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "High Quality",
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.text.withAlpha(80),
                  ),
                ),
                Text(
                  "Smallest File",
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.text.withAlpha(80),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick presets
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(8)
                  : Colors.black.withAlpha(6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _presetChip("Low", 0.2, isLow, colors, isDark),
                _presetChip("Balanced", 0.5, isBalanced, colors, isDark),
                _presetChip("High", 0.8, isHigh, colors, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(
    String label,
    double value,
    bool isActive,
    AppColors colors,
    bool isDark,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => compressionLevel = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? Colors.black.withAlpha(isDark ? 30 : 10)
                    : Colors.transparent,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? colors.primary : colors.text.withAlpha(100),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Target Size Input ──────────────────────────────────────────
  Widget _targetSizeInput(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Target Size",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetSizeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    hintText: "Enter target size...",
                    hintStyle: TextStyle(color: colors.text.withAlpha(80)),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(8)
                        : Colors.black.withAlpha(6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _targetSizeUnit,
                    dropdownColor: colors.card,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'KB', child: Text('KB')),
                      DropdownMenuItem(value: 'MB', child: Text('MB')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _targetSizeUnit = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "We will try to compress nearest to the target.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Output Name Input ──────────────────────────────────────────
  Widget _outputNameInput(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
        ),
      ),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_rounded,
                size: 16,
                color: colors.text.withAlpha(120),
              ),
              const SizedBox(width: 8),
              Text(
                "Output File Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "(optional)",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.text.withAlpha(80),
                ),
              ),
            ],
          ),

          TextField(
            controller: _outputNameCtrl,
            style: TextStyle(color: colors.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: "e.g. MyCompressedFile",
              hintStyle: TextStyle(
                color: colors.text.withAlpha(80),
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withAlpha(8)
                  : Colors.black.withAlpha(6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          // _compressButton(colors),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _compress,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.compress_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Compress Now",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compress Button ────────────────────────────────────────────
  // Widget _compressButton(AppColors colors) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 56,
  //     child: DecoratedBox(
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [colors.primary, colors.accent],
  //           begin: Alignment.centerLeft,
  //           end: Alignment.centerRight,
  //         ),
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: colors.primary.withAlpha(80),
  //             blurRadius: 16,
  //             offset: const Offset(0, 6),
  //           ),
  //         ],
  //       ),
  //       child: ElevatedButton(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.transparent,
  //           shadowColor: Colors.transparent,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //         ),
  //         onPressed: _compress,
  //         child: const Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.compress_rounded, color: Colors.white, size: 22),
  //             SizedBox(width: 10),
  //             Text(
  //               "Compress Now",
  //               style: TextStyle(
  //                 fontSize: 17,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //                 letterSpacing: -0.3,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ─── Error Card ─────────────────────────────────────────────────
  Widget _errorCard(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
