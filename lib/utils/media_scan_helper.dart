import 'dart:io';
import 'package:flutter/services.dart';

/// Notifies Android's MediaStore about a new/changed file so it
/// appears in file managers, galleries, and other apps immediately.
class MediaScanHelper {
  static const _channel = MethodChannel(
    'com.legendarysoftware.compress_pdf_redpdf/media_scan',
  );

  /// Scans a single file path. No-op on non-Android platforms.
  static Future<void> scanFile(String path) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scanFile', {'path': path});
    } catch (_) {
      // Silently ignore — scanning is best-effort
    }
  }
}
