import 'dart:typed_data';

/// Download PDF on web platform
void downloadPdfWeb(Uint8List bytes, String filename) {
  throw UnsupportedError('Not on web platform');
}

/// Print PDF on web platform  
void printPdfWeb(Uint8List bytes) {
  throw UnsupportedError('Not on web platform');
}
