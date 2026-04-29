import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

class PdfProvider with ChangeNotifier {
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<File?> compressPdf({
    required File inputFile,
    required double level,
    required String storagePath,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      // PdfManipulator takes imageQuality and imageScale
      // Map our level (0.0 to 1.0) to these properties
      int imageQuality;
      double imageScale;
      bool unEmbedFonts;

      if (level > 0.67) {         // HIGH compression (smallest file)
        imageQuality = 35;
        imageScale = 0.4;
        unEmbedFonts = true;
      } else if (level > 0.34) {  // MEDIUM/BALANCED
        imageQuality = 60;
        imageScale = 0.6;
        unEmbedFonts = true;
      } else {                    // LOW compression (high quality)
        imageQuality = 80;
        imageScale = 0.8;
        unEmbedFonts = false;
      }

      final String? tempCompressedPath = await PdfManipulator().pdfCompressor(
        params: PDFCompressorParams(
          pdfPath: inputFile.path,
          imageQuality: imageQuality,
          imageScale: imageScale,
          unEmbedFonts: unEmbedFonts,
        ),
      );

      _isProcessing = false;
      notifyListeners();

      if (tempCompressedPath != null) {
        final tempFile = File(tempCompressedPath);
        
        // Ensure storage directory exists
        final targetDir = Directory(storagePath);
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        final finalPath = '${targetDir.path}/redpdf_comprss_${DateTime.now().millisecondsSinceEpoch}.pdf';
        
        final savedFile = await tempFile.copy(finalPath);
        return savedFile;
      } else {
        return null;
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }
}
