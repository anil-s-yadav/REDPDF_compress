import 'dart:convert';

enum CompressionKind { pdf, image }

class CompressionHistoryItem {
  final String id;
  final CompressionKind kind;
  final String title;
  final String sourcePath;
  final String outputPath;
  final int sourceBytes;
  final int outputBytes;
  final DateTime createdAt;

  const CompressionHistoryItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.sourcePath,
    required this.outputPath,
    required this.sourceBytes,
    required this.outputBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'sourcePath': sourcePath,
        'outputPath': outputPath,
        'sourceBytes': sourceBytes,
        'outputBytes': outputBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  static CompressionHistoryItem fromJson(Map<String, dynamic> json) {
    return CompressionHistoryItem(
      id: json['id'] as String,
      kind: CompressionKind.values.firstWhere(
        (e) => e.name == (json['kind'] as String),
        orElse: () => CompressionKind.pdf,
      ),
      title: json['title'] as String,
      sourcePath: json['sourcePath'] as String,
      outputPath: json['outputPath'] as String,
      sourceBytes: (json['sourceBytes'] as num).toInt(),
      outputBytes: (json['outputBytes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static String encodeList(List<CompressionHistoryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<CompressionHistoryItem> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((m) => CompressionHistoryItem.fromJson(m.cast<String, dynamic>()))
        .toList();
  }
}

