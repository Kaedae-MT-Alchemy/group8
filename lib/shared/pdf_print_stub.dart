import 'dart:typed_data';

/// Printing is only wired up on the web; elsewhere callers save the file.
Future<bool> printPdf(Uint8List bytes) async => false;
