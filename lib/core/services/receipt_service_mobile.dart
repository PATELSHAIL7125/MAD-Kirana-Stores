import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

/// Mobile-specific implementation for sharing PDFs
Future<void> sharePdfPlatform(Uint8List bytes, String filename) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes);
  
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Receipt from Invoiz',
  );
}

/// Mobile-specific implementation for printing PDFs
Future<void> printPdfPlatform(Uint8List bytes) async {
  await Printing.layoutPdf(
    onLayout: (format) async => bytes,
  );
}
