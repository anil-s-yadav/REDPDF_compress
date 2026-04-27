import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:compress_pdf_redpdf/models/compression_history_item.dart';
import 'package:compress_pdf_redpdf/providers/history_provider.dart';
import 'package:compress_pdf_redpdf/screens/success_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class CompressImageScreen extends StatefulWidget {
  final File? initialFile;
  final int? initialBytes;

  const CompressImageScreen({super.key, this.initialFile, this.initialBytes});

  @override
  State<CompressImageScreen> createState() => _CompressImageScreenState();
}

class _CompressImageScreenState extends State<CompressImageScreen> {
  double quality = 80;
  String preset = "Medium";
  String _selectedFormat = 'jpg';

  File? _selectedImage;
  int? _selectedBytes;
  int? _srcW;
  int? _srcH;

  // user choice
  bool _doCompress = true;
  bool _doResize = false;
  bool _keepAspect = true;

  bool _isWorking = false;
  String? _error;

  final TextEditingController _wCtrl = TextEditingController();
  final TextEditingController _hCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _selectedImage = widget.initialFile;
      _selectedBytes = widget.initialBytes;
      _readImageDimensions(widget.initialFile!).then((dims) {
        if (mounted && dims != null) {
          setState(() {
            _srcW = dims.$1;
            _srcH = dims.$2;
            _wCtrl.text = _srcW.toString();
            _hCtrl.text = _srcH.toString();
          });
        }
      });
    }

    _wCtrl.addListener(() => setState(() {}));
    _hCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
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
  }

  void _applyPreset(String p) {
    setState(() {
      preset = p;
      switch (p) {
        case 'Low':
          quality = 92;
          break;
        case 'Medium':
          quality = 80;
          break;
        case 'High':
          quality = 60;
          break;
        default:
          quality = 80;
      }
    });
  }

  int? _parsePx(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null) return null;
    if (v <= 0) return null;
    return v;
  }

  Future<void> _run() async {
    final src = _selectedImage;
    if (src == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }
    if (!_doCompress && !_doResize) {
      setState(
        () => _error = 'Select at least one action: Compress or Resize.',
      );
      return;
    }

    final targetW = _doResize ? _parsePx(_wCtrl.text) : null;
    final targetH = _doResize ? _parsePx(_hCtrl.text) : null;
    if (_doResize && (targetW == null && targetH == null)) {
      setState(() => _error = 'Enter at least width or height for resize.');
      return;
    }

    setState(() {
      _isWorking = true;
      _error = null;
    });

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return;
        }
      }

      final beforeBytes = await src.length();
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();

      // Use temporary directory for the compressed file
      final tempDir = await getTemporaryDirectory();

      final originalName = src.path.split(Platform.pathSeparator).last;
      final nameWithoutExt = originalName.contains('.')
          ? originalName.substring(0, originalName.lastIndexOf('.'))
          : (originalName.isEmpty ? 'image' : originalName);

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final outPath =
          '${tempDir.path}${Platform.pathSeparator}image_${stamp}_$nameWithoutExt.$_selectedFormat';

      final compressQuality = _doCompress ? quality.round().clamp(1, 100) : 100;

      CompressFormat format;
      switch (_selectedFormat) {
        case 'png':
          format = CompressFormat.png;
          break;
        case 'webp':
          format = CompressFormat.webp;
          break;
        default:
          format = CompressFormat.jpeg;
      }

      int? minW;
      int? minH;
      if (_doResize) {
        if (_keepAspect) {
          minW = targetW;
          minH = targetH;
          if (targetW != null && targetH != null) {
            final sw = _srcW ?? targetW;
            final sh = _srcH ?? targetH;
            final scaleW = targetW / sw;
            final scaleH = targetH / sh;
            if (scaleW < scaleH) {
              minH = null;
            } else {
              minW = null;
            }
          }
        } else {
          minW = targetW;
          minH = targetH;
        }
      }

      final outFile = await FlutterImageCompress.compressAndGetFile(
        src.path,
        outPath,
        quality: compressQuality,
        minWidth: minW ?? 1920,
        minHeight: minH ?? 1080,
        format: format,
        keepExif: true,
      );

      if (outFile == null) {
        throw StateError('Failed to process image.');
      }

      File tempFile = File(outFile.path);
      final afterBytes = await tempFile.length();
      File savedFile = tempFile;

      // Use MediaStore for public storage on Android
      if (Platform.isAndroid) {
        MediaStore.appFolder = "RedPDF";
        final mediaStore = MediaStore();

        // Save to Pictures or Download? Usually Pictures for images,
        // but user asked for Download/RedPDF specifically in instructions
        await mediaStore.saveFile(
          tempFilePath: outFile.path,
          dirType: DirType.download,
          dirName: DirName.download,
          relativePath: "RedPDF",
        );
      } else {
        // Fallback or iOS: copy to settings storage location
        final targetDir = Directory(settings.storageLocation);
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final finalPath =
            '${targetDir.path}${Platform.pathSeparator}image_${stamp}_$nameWithoutExt.$_selectedFormat';
        savedFile = await savedFile.copy(finalPath);
      }

      if (!mounted) return;

      context.read<HistoryProvider>().add(
        CompressionHistoryItem(
          id: outFile.path,
          kind: CompressionKind.image,
          title: '$nameWithoutExt.$_selectedFormat',
          sourcePath: src.path,
          outputPath: outFile.path,
          sourceBytes: beforeBytes,
          outputBytes: afterBytes,
          createdAt: DateTime.now(),
        ),
      );

      Navigator.pushNamed(
        context,
        '/success',
        arguments: SuccessScreenArgs(
          title: 'Image processed',
          subtitle: _doCompress && _doResize
              ? 'Compressed and resized successfully.'
              : _doCompress
              ? 'Compressed successfully.'
              : 'Resized successfully.',
          filePath: outFile.path,
          isPdf: false,
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Image processing failed. ${e.toString()}');
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
    final colors = isDark
        ? AppThemeColors.imageDark
        : AppThemeColors.imageLight;

    return Scaffold(
      backgroundColor: colors.bg,
      // bottomNavigationBar: _bottomNav(isDark),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _topBar(isDark),s
                  // const SizedBox(height: 20),
                  _title(isDark),
                  const SizedBox(height: 20),

                  _imageCard(isDark),
                  const SizedBox(height: 25),

                  _modeSelector(isDark),
                  const SizedBox(height: 20),

                  if (_doCompress) ...[
                    _qualitySlider(isDark),
                    const SizedBox(height: 25),
                    _presetSelector(isDark),
                  ],

                  _dimensionInputs(isDark),
                  const SizedBox(height: 35),

                  _formatSelector(isDark),
                  const SizedBox(height: 20), _outcomeCard(isDark),
                  const SizedBox(height: 35),

                  _compressButton(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.text),
                      ),
                    ),
                  ], // end if
                ], // end children
              ), // end Column
            ), // end SingleChildScrollView
          ), // end ConstrainedBox
        ), // end Center
      ), // end SafeArea
    ); // end Scaffold
  }

  // Widget _topBar(bool isDark) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Row(
  //         children: [
  //           Container(
  //             height: 36,
  //             width: 36,
  //             decoration: BoxDecoration(
  //               color: Colors.blue,
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: const Icon(Icons.grid_view, color: Colors.white),
  //           ),
  //           const SizedBox(width: 10),
  //           Text(
  //             "RedPDF",
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? Colors.white : Colors.black,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _title(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compress Image",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "High-quality compression for professional results.",
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _imageCard(bool isDark) {
    final file = _selectedImage;
    final name = file == null
        ? 'No image selected'
        : file.uri.pathSegments.last;
    final meta = (_selectedBytes == null || _srcW == null || _srcH == null)
        ? 'Tap “Change” to choose an image'
        : '${_formatBytes(_selectedBytes!)} • $_srcW x $_srcH';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: file == null
                    ? Container(
                        height: 180,
                        width: double.infinity,
                        color: (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 52,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Image.file(
                        file,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                bottom: 10,
                right: 0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: _isWorking ? null : _pickImage,
                  icon: const Icon(Icons.refresh),
                  label: Text(file == null ? "Select" : "Change"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(meta, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qualitySlider(bool isDark) {
    if (!_doCompress) {
      return Opacity(
        opacity: 0.55,
        child: IgnorePointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Compression Quality",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "—",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(value: 80, min: 0, max: 100, onChanged: null),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("SMALLER SIZE", style: TextStyle(color: Colors.grey)),
                  Text("BEST QUALITY", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Compression Quality",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${quality.toInt()}%",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: quality,
          min: 0,
          max: 100,
          activeColor: Colors.blue,
          onChanged: (val) {
            setState(() => quality = val);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("SMALLER SIZE", style: TextStyle(color: Colors.grey)),
            Text("BEST QUALITY", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _presetSelector(bool isDark) {
    if (!_doCompress) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Compression Preset",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        Container(
          padding: EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["Low", "Medium", "High"].map((e) {
              final selected = preset == e;
              return GestureDetector(
                onTap: () => _applyPreset(e),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    e,
                    style: TextStyle(
                      color: selected ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _dimensionInputs(bool isDark) {
    if (!_doResize) return const SizedBox.shrink();
    final colors = isDark
        ? AppThemeColors.imageDark
        : AppThemeColors.imageLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Target Dimensions (px)",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                const Text("Keep ratio", style: TextStyle(color: Colors.grey)),
                Switch(
                  value: _keepAspect,
                  activeThumbColor: colors.primary,

                  // inactiveThumbColor: colors.text,
                  onChanged: (v) => setState(() => _keepAspect = v),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _inputBox(
                "W",
                "e.g. 2048",
                controller: _wCtrl,
                color: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _inputBox(
                "H",
                "e.g. 1536",
                controller: _hCtrl,
                color: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inputBox(
    String label,
    String hint, {
    required TextEditingController controller,
    required AppColors color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: color.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: color.text.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSelector(bool isDark) {
    final bg = isDark ? Colors.grey.shade900 : Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose Action",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _pill(
                  label: "Compress",
                  selected: _doCompress && !_doResize,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _doCompress = true;
                          _doResize = false;
                        }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pill(
                  label: "Resize",
                  selected: !_doCompress && _doResize,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _doCompress = false;
                          _doResize = true;
                        }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pill(
                  label: "Both",
                  selected: _doCompress && _doResize,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _doCompress = true;
                          _doResize = true;
                        }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _estimatedRatio() {
    double ratio = 1.0;

    // Estimate based on quality
    if (_doCompress) {
      if (quality >= 90) {
        ratio *= 0.75;
      } else if (quality >= 75) {
        ratio *= 0.45;
      } else if (quality >= 50) {
        ratio *= 0.25;
      } else {
        ratio *= 0.15;
      }
    }

    // Estimate based on dimension reduction
    if (_doResize) {
      final tw = double.tryParse(_wCtrl.text) ?? _srcW?.toDouble() ?? 1.0;
      final th = double.tryParse(_hCtrl.text) ?? _srcH?.toDouble() ?? 1.0;
      final ow = _srcW?.toDouble() ?? 1.0;
      final oh = _srcH?.toDouble() ?? 1.0;
      final areaRatio = (tw * th) / (ow * oh);
      ratio *= areaRatio;
    }

    // Clamp between 1% and 99%
    return ratio.clamp(0.01, 0.99);
  }

  Widget _outcomeCard(bool isDark) {
    if (_selectedImage == null || _selectedBytes == null) {
      return const SizedBox.shrink();
    }

    final estRatio = _estimatedRatio();
    final estBytes = (_selectedBytes! * estRatio).round();
    final savedPct = ((1 - estRatio) * 100).ceil().clamp(0, 99);

    final bg = isDark ? Colors.grey.shade900 : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
      ),
      child: Column(
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
                    color: Colors.blue.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "~${_formatBytes(estBytes)}",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 15,
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
                  "-$savedPct%",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: estRatio,
              minHeight: 4,
              backgroundColor: isDark ? Colors.black26 : Colors.grey.shade100,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _compressButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _isWorking ? null : _run,
        icon: const Icon(Icons.hd, color: Colors.white),
        label: Text(
          _isWorking
              ? "Processing…"
              : (_doResize && !_doCompress ? "Resize Now" : "Compress Now"),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _formatSelector(bool isDark) {
    final formats = ['jpg', 'png', 'webp'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.save_as, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                "Save As",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: formats.map((f) {
              final isSelected = _selectedFormat == f;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFormat = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          f.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
