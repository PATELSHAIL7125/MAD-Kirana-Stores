import 'dart:typed_data';
import 'dart:html' as html;

/// Web-specific implementation for sharing PDFs
Future<void> sharePdfPlatform(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Web-specific implementation for printing PDFs
Future<void> printPdfPlatform(Uint8List bytes) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Open in new window for printing
  html.window.open(url, '_blank');
  
  // Clean up after a delay
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}
