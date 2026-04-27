import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:external_path/external_path.dart';

enum CompressionLevel { low, balanced, high }

class SettingsProvider with ChangeNotifier {
  static const _storageKey = 'storage_location';
  static const _compressionKey = 'default_compression';

  String _storageLocation = '';
  CompressionLevel _defaultCompression = CompressionLevel.balanced;

  String get storageLocation => _storageLocation;
  CompressionLevel get defaultCompression => _defaultCompression;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Default storage location
    String defaultPath = '';
    if (Platform.isAndroid) {
      try {
        final d = await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOAD);
        defaultPath = '$d/RedPDF';
      } catch (e) {
        defaultPath = '/storage/emulated/0/Download/RedPDF';
      }
    } else {
      defaultPath = 'RedPDF'; 
    }

    _storageLocation = prefs.getString(_storageKey) ?? defaultPath;
    
    final compLevelStr = prefs.getString(_compressionKey);
    _defaultCompression = CompressionLevel.values.firstWhere(
      (e) => e.name == compLevelStr,
      orElse: () => CompressionLevel.balanced,
    );
    
    notifyListeners();
  }

  Future<void> setStorageLocation(String path) async {
    _storageLocation = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, path);
  }

  Future<void> setDefaultCompression(CompressionLevel level) async {
    _defaultCompression = level;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_compressionKey, level.name);
  }

  // Map CompressionLevel to our numeric level (0.0 to 1.0)
  double get numericCompressionLevel {
    switch (_defaultCompression) {
      case CompressionLevel.low:
        return 0.2;
      case CompressionLevel.balanced:
        return 0.5;
      case CompressionLevel.high:
        return 0.8;
    }
  }
}
