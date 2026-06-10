import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Renders a PDF file in-app with pinch-to-zoom.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.path),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
      ),
      body: PdfViewPinch(controller: _controller),
    );
  }
}
