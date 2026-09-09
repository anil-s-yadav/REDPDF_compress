import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:compress_pdf_redpdf/models/compression_history_item.dart';
import 'package:compress_pdf_redpdf/providers/history_provider.dart';
import 'package:compress_pdf_redpdf/providers/settings_provider.dart';
import 'package:compress_pdf_redpdf/screens/processing_screen.dart';
import 'package:compress_pdf_redpdf/screens/success_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:compress_pdf_redpdf/utils/media_store_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:saf/saf.dart';

class CompressImageScreen extends StatefulWidget {
  final File? initialFile;
  final int? initialBytes;

  const CompressImageScreen({super.key, this.initialFile, this.initialBytes});

  @override
  State<CompressImageScreen> createState() => _CompressImageScreenState();
}

class _CompressImageScreenState extends State<CompressImageScreen>
    with SingleTickerProviderStateMixin {
  double quality = 80.0;
  String preset = "Medium";
  String _selectedFormat = 'jpg';

  File? _selectedImage;
  int? _selectedBytes;
  int? _srcW;
  int? _srcH;

  bool _doResize = false;
  bool _keepAspect = true;

  bool _useTargetSize = false;
  final TextEditingController _targetSizeCtrl = TextEditingController();
  final TextEditingController _outputNameCtrl = TextEditingController();
  String _targetSizeUnit = 'MB';

  final TextEditingController _wCtrl = TextEditingController();
  final TextEditingController _hCtrl = TextEditingController();

  late TabController _modeTabController;
  BoxDecoration? _tabIndicator;
  Color? _tabIndicatorColor;
  Widget? _cachedModeToggleWidget;

  String? _error;

  Timer? _calcDebounce;
  int? _realCompressedBytes;
  bool _isCalculatingEstimate = false;
  int _calcRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialFile;
    _selectedBytes = widget.initialBytes;

    if (widget.initialFile != null) {
      _readImageDimensions(widget.initialFile!).then((dims) {
        if (mounted && dims != null) {
          setState(() {
            _srcW = dims.$1;
            _srcH = dims.$2;
            _wCtrl.text = _srcW.toString();
            _hCtrl.text = _srcH.toString();
          });
          _triggerRealtimeEstimate(immediate: true);
        }
      });
    }

    _modeTabController = TabController(length: 2, vsync: this);
    _modeTabController.addListener(() {
      if (!_modeTabController.indexIsChanging) {
        setState(() => _useTargetSize = _modeTabController.index == 1);
        _triggerRealtimeEstimate(immediate: true);
      }
    });
  }

  @override
  void dispose() {
    _calcDebounce?.cancel();
    _modeTabController.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    _targetSizeCtrl.dispose();
    _outputNameCtrl.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    const kb = 1024.0;
    const mb = kb * 1024.0;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<(int, int)?> _readImageDimensions(File file) async {
    try {
      final data = await file.readAsBytes();
      final c = Completer<ui.Image>();
      ui.decodeImageFromList(data, (img) => c.complete(img));
      final img = await c.future;
      return (img.width, img.height);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    setState(() => _error = null);
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
    final dims = await _readImageDimensions(file);

    if (!mounted) return;
    setState(() {
      _selectedImage = file;
      _selectedBytes = bytes;
      _srcW = dims?.$1;
      _srcH = dims?.$2;
      if (_srcW != null && _srcH != null) {
        _wCtrl.text = _srcW.toString();
        _hCtrl.text = _srcH.toString();
      } else {
        _wCtrl.text = '';
        _hCtrl.text = '';
      }
    });
    _triggerRealtimeEstimate(immediate: true);
  }

  void _viewSelectedImage() {
    final file = _selectedImage;
    if (file == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withAlpha(230),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 5.0,
                child: Image.file(file),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncPresetWithQuality(double q) {
    if (q >= 88) {
      preset = "Low";
    } else if (q >= 72) {
      preset = "Medium";
    } else {
      preset = "High";
    }
  }

  void _applyPreset(String p) {
    setState(() {
      preset = p;
      switch (p) {
        case 'Low':
          quality = 92.0;
          break;
        case 'Medium':
          quality = 80.0;
          break;
        case 'High':
          quality = 60.0;
          break;
        default:
          quality = 80.0;
      }
    });
    _triggerRealtimeEstimate(immediate: true);
  }

  void _onWidthChanged(String val) {
    if (!_keepAspect || _srcW == null || _srcH == null || _srcW == 0) {
      setState(() {});
      _triggerRealtimeEstimate();
      return;
    }
    final w = int.tryParse(val.trim());
    if (w != null && w > 0) {
      final newH = ((w / _srcW!) * _srcH!).round();
      _hCtrl.value = TextEditingValue(
        text: newH.toString(),
        selection: TextSelection.collapsed(offset: newH.toString().length),
      );
    }
    setState(() {});
    _triggerRealtimeEstimate();
  }

  void _onHeightChanged(String val) {
    if (!_keepAspect || _srcW == null || _srcH == null || _srcH == 0) {
      setState(() {});
      _triggerRealtimeEstimate();
      return;
    }
    final h = int.tryParse(val.trim());
    if (h != null && h > 0) {
      final newW = ((h / _srcH!) * _srcW!).round();
      _wCtrl.value = TextEditingValue(
        text: newW.toString(),
        selection: TextSelection.collapsed(offset: newW.toString().length),
      );
    }
    setState(() {});
    _triggerRealtimeEstimate();
  }

  int? _parsePx(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null) return null;
    if (v <= 0) return null;
    return v;
  }

  (int?, int?) _getTargetDimensions() {
    if (!_doResize) return (null, null);
    final tw = _parsePx(_wCtrl.text);
    final th = _parsePx(_hCtrl.text);
    final sw = _srcW;
    final sh = _srcH;

    if (tw == null && th == null) return (null, null);

    if (tw != null && th != null) {
      if (_keepAspect && sw != null && sh != null && sw > 0 && sh > 0) {
        final scale = math.min(tw / sw, th / sh);
        final ow = (sw * scale).round().clamp(1, 10000);
        final oh = (sh * scale).round().clamp(1, 10000);
        return (ow, oh);
      }
      return (tw, th);
    } else if (tw != null) {
      if (_keepAspect && sw != null && sh != null && sw > 0) {
        final oh = ((tw / sw) * sh).round().clamp(1, 10000);
        return (tw, oh);
      }
      return (tw, sh);
    } else {
      if (_keepAspect && sw != null && sh != null && sh > 0) {
        final ow = ((th! / sh) * sw).round().clamp(1, 10000);
        return (ow, th);
      }
      return (sw, th);
    }
  }

  void _triggerRealtimeEstimate({bool immediate = false}) {
    _calcDebounce?.cancel();
    if (immediate) {
      _calculateRealtimeSize();
    } else {
      _calcDebounce = Timer(
        const Duration(milliseconds: 200),
        _calculateRealtimeSize,
      );
    }
  }

  Future<void> _calculateRealtimeSize() async {
    final src = _selectedImage;
    if (src == null || !src.existsSync()) {
      if (mounted) setState(() => _realCompressedBytes = null);
      return;
    }

    final int reqId = ++_calcRequestId;

    if (mounted) {
      setState(() => _isCalculatingEstimate = true);
    }

    try {
      final dims = _getTargetDimensions();
      int compressQuality = quality.round().clamp(1, 100);

      if (_useTargetSize &&
          _targetSizeCtrl.text.isNotEmpty &&
          _selectedBytes != null &&
          _selectedBytes! > 0) {
        final target = double.tryParse(_targetSizeCtrl.text) ?? 0;
        if (target > 0) {
          final targetBytes =
              (target * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024)).round();
          compressQuality =
              await _findBestQualityForTarget(src, targetBytes, dims);
        }
      }

      final bytes = await _performCompression(
        srcFile: src,
        quality: compressQuality,
        formatStr: _selectedFormat,
        targetW: dims.$1,
        targetH: dims.$2,
        keepAspect: _keepAspect,
      );

      if (reqId != _calcRequestId) return;

      if (mounted) {
        setState(() {
          _realCompressedBytes = bytes?.length;
          _isCalculatingEstimate = false;
        });
      }
    } catch (_) {
      if (reqId == _calcRequestId && mounted) {
        setState(() {
          _isCalculatingEstimate = false;
        });
      }
    }
  }

  Future<int> _findBestQualityForTarget(
    File srcFile,
    int targetBytes,
    (int?, int?) dims,
  ) async {
    int low = 5;
    int high = 95;
    int bestQ = 80;
    int bestDiff = 999999999;

    for (int iter = 0; iter < 4; iter++) {
      final mid = ((low + high) / 2).round();
      final testBytes = await _performCompression(
        srcFile: srcFile,
        quality: mid,
        formatStr: _selectedFormat,
        targetW: dims.$1,
        targetH: dims.$2,
        keepAspect: _keepAspect,
      );
      if (testBytes == null) break;
      final diff = (testBytes.length - targetBytes).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestQ = mid;
      }
      if (testBytes.length > targetBytes) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
      if (low > high) break;
    }
    return bestQ;
  }

  Future<Uint8List?> _performCompression({
    required File srcFile,
    required int quality,
    required String formatStr,
    int? targetW,
    int? targetH,
    bool keepAspect = true,
  }) async {
    CompressFormat format;
    switch (formatStr) {
      case 'png':
        format = CompressFormat.png;
        break;
      case 'webp':
        format = CompressFormat.webp;
        break;
      default:
        format = CompressFormat.jpeg;
    }

    final sw = _srcW;
    final sh = _srcH;

    final bool needsCustomResize = targetW != null &&
        targetH != null &&
        sw != null &&
        sh != null &&
        ((targetW > sw || targetH > sh) ||
            (!keepAspect && (targetW / targetH - sw / sh).abs() > 0.01));

    if (needsCustomResize) {
      final rawBytes = await srcFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: targetW,
        targetHeight: targetH,
        allowUpscaling: true,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final resizedBytes = byteData.buffer.asUint8List();

      return await FlutterImageCompress.compressWithList(
        resizedBytes,
        quality: quality,
        format: format,
        autoCorrectionAngle: true,
      );
    }

    return await FlutterImageCompress.compressWithFile(
      srcFile.path,
      quality: quality,
      minWidth: targetW ?? (sw ?? 1920),
      minHeight: targetH ?? (sh ?? 1080),
      format: format,
      keepExif: false,
      autoCorrectionAngle: true,
    );
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

    double ratio = 1.0;

    final double qNorm = quality / 100.0;
    ratio *= (qNorm * qNorm * 0.8) + 0.1;

    if (_doResize) {
      final dims = _getTargetDimensions();
      final tw = dims.$1?.toDouble() ?? _srcW?.toDouble() ?? 1.0;
      final th = dims.$2?.toDouble() ?? _srcH?.toDouble() ?? 1.0;
      final ow = _srcW?.toDouble() ?? 1.0;
      final oh = _srcH?.toDouble() ?? 1.0;
      if (ow > 0 && oh > 0) {
        final areaRatio = (tw * th) / (ow * oh);
        ratio *= areaRatio.clamp(0.05, 1.0);
      }
    }

    return ratio.clamp(0.01, 0.99);
  }

  Future<void> _run() async {
    final src = _selectedImage;
    if (src == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }

    final dims = _getTargetDimensions();
    if (_doResize && (dims.$1 == null && dims.$2 == null)) {
      setState(() => _error = 'Enter at least width or height for resize.');
      return;
    }

    setState(() => _error = null);

    final doResize = _doResize;
    final keepAspect = _keepAspect;
    final selectedFormat = _selectedFormat;

    int compressQuality = quality.round().clamp(1, 100);
    if (_useTargetSize &&
        _targetSizeCtrl.text.isNotEmpty &&
        _selectedBytes != null &&
        _selectedBytes! > 0) {
      final target = double.tryParse(_targetSizeCtrl.text) ?? 0;
      if (target > 0) {
        final targetBytes =
            (target * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024)).round();
        compressQuality =
            await _findBestQualityForTarget(src, targetBytes, dims);
      }
    }

    final subtitle = doResize
        ? 'Compressed and resized successfully.'
        : 'Saved to your device.';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          isPdf: false,
          title: 'Processing Image',
          processTask: (ctx) async {
            final settings = ctx.read<SettingsProvider>();
            final history = ctx.read<HistoryProvider>();
            final beforeBytes = await src.length();

            final tempDir = await getTemporaryDirectory();
            final stamp = DateTime.now().millisecondsSinceEpoch;
            String outFileName = 'redpdf_cmp_$stamp.$selectedFormat';
            if (_outputNameCtrl.text.trim().isNotEmpty) {
              String name = _outputNameCtrl.text.trim();
              if (!name.toLowerCase().endsWith('.$selectedFormat')) {
                final dotIdx = name.lastIndexOf('.');
                if (dotIdx != -1) {
                  name = '${name.substring(0, dotIdx)}.$selectedFormat';
                } else {
                  name += '.$selectedFormat';
                }
              }
              outFileName = name;
            }
            final outPath =
                '${tempDir.path}${Platform.pathSeparator}$outFileName';

            final compressedBytes = await _performCompression(
              srcFile: src,
              quality: compressQuality,
              formatStr: selectedFormat,
              targetW: dims.$1,
              targetH: dims.$2,
              keepAspect: keepAspect,
            );

            if (compressedBytes == null || compressedBytes.isEmpty) {
              throw StateError('Failed to process image.');
            }

            final outFile = File(outPath);
            await outFile.writeAsBytes(compressedBytes, flush: true);

            final tempFile = outFile;
            final afterBytes = compressedBytes.length;

            // Copy to app's storage location
            final mime = selectedFormat == 'png'
                ? 'image/png'
                : (selectedFormat == 'webp' ? 'image/webp' : 'image/jpeg');
            String? savedPath;
            if (settings.storageLocation.startsWith('content://')) {
              final doc = await Saf().pasteLocalFile(
                tempFile.path,
                settings.storageLocation,
                outFileName,
                mime,
              );
              savedPath = doc.uri;
            } else {
              savedPath = await MediaStoreHelper.saveFileToDownloads(
                tempFilePath: tempFile.path,
                fileName: outFileName,
                mimeType: mime,
              );
            }

            if (savedPath == null) {
              throw Exception("Failed to save image to device storage");
            }
            final savedFile = File(savedPath);

            history.add(
              CompressionHistoryItem(
                id: savedFile.path,
                kind: CompressionKind.image,
                title: outFileName,
                sourcePath: src.path,
                outputPath: savedFile.path,
                sourceBytes: beforeBytes,
                outputBytes: afterBytes,
                createdAt: DateTime.now(),
              ),
            );

            return SuccessScreenArgs(
              title: 'Image compressed',
              subtitle: subtitle,
              filePath: savedFile.path,
              previewPath: tempFile.path,
              isPdf: false,
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
    final colors = isDark
        ? AppThemeColors.imageDark
        : AppThemeColors.imageLight;

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  children: [
                    _fileCard(colors, isDark),
                    const SizedBox(height: 20),
                    _modeToggle(colors, isDark),
                    const SizedBox(height: 16),
                    _useTargetSize
                        ? _targetSizeInput(colors, isDark)
                        : _compressionSlider(colors, isDark),
                    const SizedBox(height: 16),
                    _optionsCard(colors, isDark),
                    const SizedBox(height: 16),
                    _outputNameInput(colors, isDark),
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
              "Compress Image",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.text,
                letterSpacing: -0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                "Reselect",
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── File Card ──────────────────────────────────────────────────
  Widget _fileCard(AppColors colors, bool isDark) {
    final file = _selectedImage;
    final name = file == null ? 'No image selected' : file.uri.pathSegments.last;
    final bytes = _selectedBytes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : colors.primary.withAlpha(22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(isDark ? 15 : 12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
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
              Icon(
                Icons.insert_drive_file_rounded,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "SELECTED IMAGE",
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
          GestureDetector(
            onTap: file == null ? _pickImage : _viewSelectedImage,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // Image thumbnail preview
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(isDark ? 30 : 15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.primary.withAlpha(25)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: file != null
                        ? Image.file(
                            file,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.image_rounded,
                            color: colors.primary,
                            size: 26,
                          ),
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
                            ? "Tap to select an image"
                            : (_srcW != null && _srcH != null
                                ? "${_formatBytes(bytes)} • $_srcW × $_srcH"
                                : _formatBytes(bytes)),
                        style: TextStyle(
                          color: colors.text.withAlpha(100),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Estimated size row ──
          if (_selectedBytes != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _estimatedRow(colors, isDark),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _realCompressedBytes != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline,
                size: 14,
                color: _realCompressedBytes != null
                    ? Colors.green.shade600
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _realCompressedBytes != null
                      ? "Real-time compressed size calculated accurately."
                      : "Calculating real compressed size...",
                  style: TextStyle(
                    fontSize: 11,
                    color: _realCompressedBytes != null
                        ? Colors.green.shade700
                        : Colors.orange,
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

  // ─── Estimated Row ──────────────────────────────────────────────
  Widget _estimatedRow(AppColors colors, bool isDark) {
    final bytes = _selectedBytes;
    final int? estBytes = _realCompressedBytes ??
        (bytes == null ? null : (bytes * _estimatedRatio()).round());

    final bool isExact = _realCompressedBytes != null;
    final bool isReduced =
        bytes != null && estBytes != null && estBytes < bytes;
    final bool isLarger =
        bytes != null && estBytes != null && estBytes > bytes;
    final double? savedPct = (bytes == null || estBytes == null || bytes == 0)
        ? null
        : (((bytes - estBytes).abs() / bytes) * 100).clamp(0, 99.9);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(6) : colors.primary.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withAlpha(isDark ? 15 : 20)),
      ),
      child: Column(
        children: [
          Row(
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
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: colors.primary.withAlpha(150),
              ),
              const SizedBox(width: 8),
              Text(
                estBytes == null
                    ? "—"
                    : (isExact
                        ? _formatBytes(estBytes)
                        : "~${_formatBytes(estBytes)}"),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_isCalculatingEstimate) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ],
              const Spacer(),
              if (savedPct != null && estBytes != null && bytes != null && bytes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isReduced
                        ? Colors.green.shade600
                        : (isLarger
                            ? Colors.amber.shade800
                            : Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isReduced
                        ? "-${savedPct.toStringAsFixed(0)}%"
                        : (isLarger
                            ? "+${savedPct.toStringAsFixed(0)}%"
                            : "0%"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
              backgroundColor:
                  isDark ? Colors.black26 : Colors.black.withAlpha(15),
              color: isLarger ? Colors.amber : colors.primary,
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
        color: isDark ? Colors.white.withAlpha(12) : const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
        ),
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
                Text("By Quality"),
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

  // ─── Compression Slider Card ────────────────────────────────────
  Widget _compressionSlider(AppColors colors, bool isDark) {
    final isLow = quality >= 88;
    final isBalanced = quality >= 72 && quality < 88;
    final isHigh = quality < 72;

    String levelDesc = isLow
        ? 'Best quality, larger file'
        : isBalanced
            ? 'Good balance of size & clarity'
            : 'Smallest file, lower quality';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : colors.primary.withAlpha(22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(isDark ? 15 : 10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
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
              Expanded(
                child: Text(
                  "Compression Quality",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                  "${quality.round()}% Quality",
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
              value: quality,
              min: 10,
              max: 100,
              divisions: 90,
              onChanged: (v) {
                setState(() {
                  quality = v;
                  _syncPresetWithQuality(v);
                });
                _triggerRealtimeEstimate();
              },
            ),
          ),

          // Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Smaller Size",
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.text.withAlpha(80),
                  ),
                ),
                Text(
                  "Best Quality",
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
                _presetChip("Low", 92.0, isLow, colors, isDark),
                _presetChip("Balanced", 80.0, isBalanced, colors, isDark),
                _presetChip("High", 60.0, isHigh, colors, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(
    String label,
    double targetVal,
    bool isSelected,
    AppColors colors,
    bool isDark,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPreset(targetVal >= 88 ? 'Low' : (targetVal >= 72 ? 'Medium' : 'High')),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : colors.text.withAlpha(120),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Target Size Card ───────────────────────────────────────────
  Widget _targetSizeInput(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : colors.primary.withAlpha(22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(isDark ? 15 : 10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  onChanged: (val) {
                    setState(() {});
                    _triggerRealtimeEstimate();
                  },
                  style: TextStyle(color: colors.text, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: "Enter target size...",
                    hintStyle: TextStyle(color: colors.text.withAlpha(90)),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(12)
                        : const Color(0xFFF6F8FC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(20)
                            : colors.primary.withAlpha(30),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.primary,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(12)
                      : const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : colors.primary.withAlpha(30),
                    width: 1.2,
                  ),
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
                        _triggerRealtimeEstimate(immediate: true);
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
              Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "We will compress nearest to the target size.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
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

  // ─── Image Options Card (Format & Dimensions) ───────────────────
  Widget _optionsCard(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : colors.primary.withAlpha(22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(isDark ? 15 : 10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Format
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 15, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                "OUTPUT FORMAT",
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Format selection chips
          Row(
            children: ['jpg', 'png', 'webp'].map((fmt) {
              final isSel = _selectedFormat == fmt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFormat = fmt);
                      _triggerRealtimeEstimate(immediate: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? colors.primary
                            : (isDark ? Colors.white.withAlpha(8) : const Color(0xFFF6F8FC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? colors.primary
                              : (isDark ? Colors.white.withAlpha(15) : colors.primary.withAlpha(25)),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        fmt.toUpperCase(),
                        style: TextStyle(
                          color: isSel ? Colors.white : colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Divider(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
          const SizedBox(height: 12),

          // Resize toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.aspect_ratio_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Resize Dimensions",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _doResize
                                ? "Custom width & height"
                                : (_srcW != null && _srcH != null
                                    ? "Original: $_srcW × $_srcH px"
                                    : "Optional custom scale"),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.text.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _doResize,
                activeTrackColor: colors.primary,
                onChanged: (val) {
                  setState(() {
                    _doResize = val;
                    if (val && _wCtrl.text.isEmpty && _srcW != null) {
                      _wCtrl.text = _srcW.toString();
                      _hCtrl.text = _srcH.toString();
                    }
                  });
                  _triggerRealtimeEstimate(immediate: true);
                },
              ),
            ],
          ),

          // Expandable dimensions if _doResize is true
          if (_doResize) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Keep Aspect Ratio",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.text.withAlpha(120),
                  ),
                ),
                Switch.adaptive(
                  value: _keepAspect,
                  activeTrackColor: colors.primary,
                  onChanged: (v) {
                    setState(() => _keepAspect = v);
                    _triggerRealtimeEstimate(immediate: true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dimInputField("Width (px)", _wCtrl, _onWidthChanged, colors, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dimInputField("Height (px)", _hCtrl, _onHeightChanged, colors, isDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dimInputField(
    String hint,
    TextEditingController ctrl,
    ValueChanged<String> onChanged,
    AppColors colors,
    bool isDark,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: colors.text.withAlpha(90), fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(12) : const Color(0xFFF6F8FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withAlpha(20) : colors.primary.withAlpha(30),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  // ─── Output Name & Compress Button Card ─────────────────────────
  Widget _outputNameInput(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : colors.primary.withAlpha(22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(isDark ? 15 : 10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
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
              Icon(
                Icons.edit_rounded,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "OUTPUT FILE NAME (OPTIONAL)",
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _outputNameCtrl,
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: colors.primary,
                size: 22,
              ),
              hintText: "e.g. MyCompressedImage",
              hintStyle: TextStyle(
                color: colors.text.withAlpha(90),
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withAlpha(12)
                  : const Color(0xFFF6F8FC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : colors.primary.withAlpha(30),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                onPressed: _run,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_size_select_small_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Compress Image",
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
