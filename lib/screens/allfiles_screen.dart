import 'dart:io';

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_view_screen.dart';

import '../models/compression_history_item.dart';
import '../providers/history_provider.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _query = '';
  List<File> _devicePdfs = [];
  bool _isLoadingPdfs = true;

  @override
  void initState() {
    super.initState();
    _fetchDevicePdfs();
  }

  Future<void> _fetchDevicePdfs() async {
    List<File> pdfs = [];
    try {
      List<Directory> dirsToSearch = [];
      if (Platform.isAndroid) {
        dirsToSearch = [
          Directory('/storage/emulated/0/Download'),
          Directory('/storage/emulated/0/Documents'),
        ];
      } else {
        final temp = await getApplicationDocumentsDirectory();
        dirsToSearch = [temp];
      }

      for (var dir in dirsToSearch) {
        if (await dir.exists()) {
          try {
            final stream = dir.list(recursive: true, followLinks: false);
            await for (var entity in stream) {
              if (entity is File &&
                  entity.path.toLowerCase().endsWith('.pdf')) {
                pdfs.add(entity);
              }
            }
          } catch (e) {
            // ignore access errors
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching device PDFs: $e");
    }

    // sort by modified date descending
    try {
      pdfs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      debugPrint("Error sorting device PDFs: $e");
    }

    if (mounted) {
      setState(() {
        _devicePdfs = pdfs;
        _isLoadingPdfs = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    const kb = 1024.0;
    const mb = kb * 1024.0;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  String _sectionFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'TODAY';
    if (d == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('MMM d, yyyy').format(d).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pdfColor = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;
    return Scaffold(
      backgroundColor: pdfColor.bg,
      body: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
              _header(),
              _searchBar(pdfColor),
              SizedBox(height: 10),
              TabBar(
                isScrollable: true,
                labelColor: pdfColor.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: pdfColor.primary,
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: "Compressed Files"),
                  Tab(text: "Device PDFs"),
                ],
              ),

              const SizedBox(height: 10),

              ///  FIXED
              Expanded(
                child: TabBarView(
                  children: [
                    Consumer<HistoryProvider>(
                      builder: (context, history, _) {
                        final items = history.items
                            .where((e) {
                              if (_query.trim().isEmpty) return true;
                              return e.title.toLowerCase().contains(
                                _query.trim().toLowerCase(),
                              );
                            })
                            .toList(growable: false);

                        if (!history.isLoaded) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              _query.trim().isEmpty
                                  ? "No compressed files yet."
                                  : "No results.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        String? lastSection;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final section = _sectionFor(item.createdAt);
                            final showHeader = lastSection != section;
                            lastSection = section;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) _sectionTitle(section),
                                _historyCard(
                                  item: item,
                                  pdfColor: pdfColor,
                                  isDark: isDark,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    _buildDevicePdfsTab(pdfColor, isDark),
                  ],
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

  Widget _buildDevicePdfsTab(AppColors pdfColor, bool isDark) {
    if (_isLoadingPdfs) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _devicePdfs
        .where((e) {
          if (_query.trim().isEmpty) return true;
          final name = e.uri.pathSegments.last;
          return name.toLowerCase().contains(_query.trim().toLowerCase());
        })
        .toList(growable: false);

    if (items.isEmpty) {
      return Center(
        child: Text(
          _query.trim().isEmpty ? "No PDFs found on device." : "No results.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final name = item.uri.pathSegments.last;
        final size = _formatBytes(item.lengthSync());
        final accent = isDark
            ? AppThemeColors.pdfDark.primary
            : AppThemeColors.pdfLight.primary;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PdfViewScreen(title: name, path: item.path),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pdfColor.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                _kindIcon(accent, isPdf: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(size, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (!await item.exists()) return;
                    await Share.shareXFiles([XFile(item.path)]);
                  },
                  icon: Icon(Icons.ios_share, color: accent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Files",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Text('Clear History'),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text(
          "Are you sure you want to delete all recently compressed PDFs from history?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clear();
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(AppColors pdfColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 45,
        decoration: BoxDecoration(
          color: pdfColor.card,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: "Search compressed files...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                onPressed: () => setState(() => _query = ''),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _historyCard({
    required CompressionHistoryItem item,
    required AppColors pdfColor,
    required bool isDark,
  }) {
    final isPdf = item.kind == CompressionKind.pdf;
    final accent = isPdf
        ? (isDark
              ? AppThemeColors.pdfDark.primary
              : AppThemeColors.pdfLight.primary)
        : (isDark
              ? AppThemeColors.imageDark.primary
              : AppThemeColors.imageLight.primary);

    final date = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(item.createdAt).toUpperCase();
    final size =
        '${_formatBytes(item.sourceBytes)} → ${_formatBytes(item.outputBytes)}';
    final savedPct = item.sourceBytes == 0
        ? null
        : (((item.sourceBytes - item.outputBytes) / item.sourceBytes) * 100)
              .clamp(0, 99.9);

    return InkWell(
      onTap: () {
        if (isPdf) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfViewScreen(title: item.title, path: item.outputPath),
            ),
          );
        } else {
          // Simple image preview dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(File(item.outputPath)),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pdfColor.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            _kindIcon(accent, isPdf: isPdf),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (savedPct != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${savedPct.toStringAsFixed(0)}% saved',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () async {
                    final f = File(item.outputPath);
                    if (!await f.exists()) return;
                    await Share.shareXFiles([XFile(item.outputPath)]);
                  },
                  icon: Icon(Icons.ios_share, color: accent, size: 20),
                ),
                IconButton(
                  onPressed: () => _showDeleteItemDialog(item),
                  icon: Icon(Icons.delete_outline, color: accent, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteItemDialog(CompressionHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete File"),
        content: Text(
          "Do you want to delete ${item.title} from your history and your device storage?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Delete actual file
              try {
                final file = File(item.outputPath);
                if (await file.exists()) {
                  await file.delete();
                }
              } catch (e) {
                debugPrint("Error deleting file: $e");
              }

              if (!context.mounted) return;
              context.read<HistoryProvider>().remove(item.id);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _kindIcon(Color accent, {required bool isPdf}) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
        color: accent,
      ),
    );
  }
}
