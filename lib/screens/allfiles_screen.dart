import 'dart:io';

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
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
                      Tab(text: "Compressed PDFs"),
                      Tab(text: "Compressed Images"),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ///  FIXED
                  Expanded(
                    child: TabBarView(
                      children: [
                        Consumer<HistoryProvider>(
                          builder: (context, history, _) {
                            return _buildHistoryTab(
                              history,
                              CompressionKind.pdf,
                              pdfColor,
                              isDark,
                            );
                          },
                        ),
                        Consumer<HistoryProvider>(
                          builder: (context, history, _) {
                            return _buildHistoryTab(
                              history,
                              CompressionKind.image,
                              pdfColor,
                              isDark,
                            );
                          },
                        ),
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

  Widget _buildHistoryTab(
    HistoryProvider history,
    CompressionKind kind,
    AppColors pdfColor,
    bool isDark,
  ) {
    final items = history.items
        .where((e) {
          if (e.kind != kind) return false;
          if (_query.trim().isEmpty) return true;
          return e.title.toLowerCase().contains(_query.trim().toLowerCase());
        })
        .toList(growable: false);

    if (!history.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          _query.trim().isEmpty
              ? "No compressed ${kind == CompressionKind.pdf ? 'PDFs' : 'images'} yet."
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
            _historyCard(item: item, pdfColor: pdfColor, isDark: isDark),
          ],
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
          final file = File(item.outputPath);
          if (!file.existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("File no longer exists at this path."),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfViewScreen(title: item.title, path: item.outputPath),
            ),
          );
        } else {
          final file = File(item.outputPath);
          if (!file.existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Image no longer exists at this path."),
              ),
            );
            return;
          }
          // Simple image preview dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(file),
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  Row(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        size,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (savedPct != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${savedPct.toStringAsFixed(0)}% saved',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () async {
                    final f = File(item.outputPath);
                    if (!await f.exists()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("File not found for sharing."),
                          ),
                        );
                      }
                      return;
                    }
                    await Share.shareXFiles([XFile(item.outputPath)]);
                  },
                  icon: Icon(Icons.ios_share, color: Colors.blue, size: 20),
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
