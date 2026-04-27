import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewScreen extends StatelessWidget {
  final String title;
  final String path;

  const PdfViewScreen({super.key, required this.title, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfViewer.file(path),
    );
  }
}
