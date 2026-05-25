import 'dart:io';

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import 'pdf_view_screen.dart';

import '../models/compression_history_item.dart';
import '../providers/history_provider.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen>
    with SingleTickerProviderStateMixin {
  String _query = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _header(pdfColor),
                const SizedBox(height: 8),
                _searchBar(pdfColor, isDark),
                const SizedBox(height: 16),
                _tabBar(pdfColor, isDark),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
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
    );
  }

  // ─── Header ─────────────────────────────────────────────────────
  Widget _header(AppColors color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Files",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Consumer<HistoryProvider>(
                builder: (context, history, _) {
                  final count = history.items.length;
                  return Text(
                    "$count compressed file${count == 1 ? '' : 's'}",
                    style: TextStyle(
                      fontSize: 13,
                      color: color.text.withAlpha(120),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: color.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: color.text),
              // shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              // ),
              color: color.bg,

              onSelected: (value) {
                if (value == 'clear') {
                  _showClearHistoryDialog();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text('Clear History'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────
  Widget _searchBar(AppColors color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 50,
        decoration: BoxDecoration(
          color: color.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(10)
                : Colors.black.withAlpha(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: color.text.withAlpha(100),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: color.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search files...",
                  hintStyle: TextStyle(
                    color: color.text.withAlpha(80),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _query = ''),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.text.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: color.text.withAlpha(120),
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────────
  Widget _tabBar(AppColors color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: color.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.primary.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: color.text.withAlpha(140),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(14),
          tabs: const [
            Tab(text: "PDFs"),
            Tab(text: "Images"),
          ],
        ),
      ),
    );
  }

  // ─── History Tab Content ────────────────────────────────────────
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
      return Center(child: CircularProgressIndicator(color: pdfColor.primary));
    }

    if (items.isEmpty) {
      return _emptyState(kind, pdfColor);
    }

    String? lastSection;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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

  // ─── Empty State ────────────────────────────────────────────────
  Widget _emptyState(CompressionKind kind, AppColors color) {
    final isPdf = kind == CompressionKind.pdf;
    final hasQuery = _query.trim().isNotEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : (isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined),
              size: 48,
              color: color.primary.withAlpha(120),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery
                ? "No results found"
                : "No ${isPdf ? 'PDFs' : 'images'} yet",
            style: TextStyle(
              color: color.text.withAlpha(160),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? "Try a different search term"
                : "Compressed ${isPdf ? 'PDFs' : 'images'} will appear here",
            style: TextStyle(color: color.text.withAlpha(90), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─── History Card ───────────────────────────────────────────────
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

    final date = DateFormat('MMM d • h:mm a').format(item.createdAt);
    final savedPct = item.sourceBytes == 0
        ? null
        : (((item.sourceBytes - item.outputBytes) / item.sourceBytes) * 100)
              .clamp(0, 99.9);

    return GestureDetector(
      onTap: () => _openFile(item, isPdf),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pdfColor.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(8)
                : Colors.black.withAlpha(6),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(isDark ? 10 : 12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            _kindIcon(accent, isPdf: isPdf, isDark: isDark),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: pdfColor.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: pdfColor.text.withAlpha(80),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          color: pdfColor.text.withAlpha(100),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Size info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pdfColor.text.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_formatBytes(item.sourceBytes)} → ${_formatBytes(item.outputBytes)}',
                          style: TextStyle(
                            color: pdfColor.text.withAlpha(130),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Saved percentage badge
                      if (savedPct != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${savedPct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  icon: Icons.share_rounded,
                  color: const Color(0xFF3D7BF5),
                  onTap: () => _shareFile(item),
                ),
                const SizedBox(height: 6),
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  color: accent,
                  onTap: () => _showDeleteItemDialog(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _kindIcon(Color accent, {required bool isPdf, required bool isDark}) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withAlpha(40), accent.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(30), width: 1),
      ),
      child: Icon(
        isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
        color: accent,
        size: 26,
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────
  Future<void> _openFile(CompressionHistoryItem item, bool isPdf) async {
    if (isPdf) {
      final file = File(item.outputPath);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File no longer exists at this path.")),
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
          const SnackBar(content: Text("Image no longer exists at this path.")),
        );
        return;
      }
      final result = await OpenFilex.open(item.outputPath);
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
    }
  }

  Future<void> _shareFile(CompressionHistoryItem item) async {
    final f = File(item.outputPath);
    if (!await f.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File not found for sharing.")),
        );
      }
      return;
    }
    await Share.shareXFiles([XFile(item.outputPath)]);
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear History"),
        content: const Text(
          "Are you sure you want to delete all compressed files from history?",
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

  void _showDeleteItemDialog(CompressionHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
}
