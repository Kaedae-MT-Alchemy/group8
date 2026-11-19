import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Opens the browser's print dialog for a PDF by loading it into a hidden
/// frame. Returns false if the browser blocks it.
Future<bool> printPdf(Uint8List bytes) async {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final frame = web.HTMLIFrameElement()
      ..src = url
      ..title = 'Print';
    frame.style
      ..position = 'fixed'
      ..right = '0'
      ..bottom = '0'
      ..width = '0'
      ..height = '0'
      ..border = '0';
    frame.onload = (web.Event _) {
      try {
        frame.contentWindow?.focus();
        frame.contentWindow?.print();
      } catch (_) {
        web.window.open(url, '_blank');
      }
    }.toJS;
    web.document.body?.append(frame);
    // Clean up later; printing keeps its own copy.
    Future.delayed(const Duration(minutes: 2), () {
      frame.remove();
      web.URL.revokeObjectURL(url);
    });
    return true;
  } catch (_) {
    return false;
  }
}
