import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

/// Helper to save files safely using MediaStore on Android 10+ (API 29+)
/// without requiring sensitive storage permissions like MANAGE_EXTERNAL_STORAGE.
class MediaStoreHelper {
  static const _channel = MethodChannel(
    'com.legendarysoftware.compress_pdf_redpdf/media_store',
  );

  /// Copies a temporary file to the public Downloads folder safely.
  /// Returns the saved absolute path if successful, otherwise null.
  static Future<String?> saveFileToDownloads({
    required String tempFilePath,
    required String fileName,
    required String mimeType,
  }) async {
    if (!Platform.isAndroid) return null;

    try {
      final savedPath = await _channel.invokeMethod<String>('saveFile', {
        'sourcePath': tempFilePath,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      return savedPath;
    } catch (e) {
      developer.log("Error saving to MediaStore: $e", name: "MediaStoreHelper");
      return null;
    }
  }
}
