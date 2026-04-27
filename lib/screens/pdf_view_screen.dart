import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewScreen extends StatefulWidget {
  final String title;
  final String path;

  const PdfViewScreen({super.key, required this.title, required this.path});

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  Uint8List? _pdfData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      final file = File(widget.path);
      if (!await file.exists()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Read file into memory to bypass native fopen scoped storage issues
      // This solves the FPDF_ERR_FILE: 2 error that PdfViewer.file causes
      final data = await file.readAsBytes();

      if (mounted) {
        setState(() {
          _pdfData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading PDF: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfData != null
          ? PdfViewer.data(_pdfData!, sourceName: widget.title)
          : const Center(child: Text("Failed to load PDF")),
    );
  }
}
