import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

String _viewType(String prefix, String url) =>
    '$prefix-${url.hashCode.toUnsigned(32).toRadixString(16)}-${url.length}';

/// An embedded page or document (PDF viewer, Office web viewer).
Widget? iframeView(String url, {String title = 'Document'}) {
  final type = _viewType('frame', url);
  if (_registered.add(type)) {
    ui_web.platformViewRegistry.registerViewFactory(type, (int _) {
      final frame = web.HTMLIFrameElement()
        ..src = url
        ..title = title
        ..allow = 'fullscreen'
        ..allowFullscreen = true;
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = '#ffffff';
      return frame;
    });
  }
  return HtmlElementView(viewType: type);
}

/// A native HTML video player with controls (MP4/WebM).
Widget? videoView(String url) {
  final type = _viewType('video', url);
  if (_registered.add(type)) {
    ui_web.platformViewRegistry.registerViewFactory(type, (int _) {
      final video = web.HTMLVideoElement()
        ..src = url
        ..controls = true
        ..preload = 'metadata'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('controlslist', 'nodownload');
      video.style
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = '#000000';
      return video;
    });
  }
  return HtmlElementView(viewType: type);
}

/// Object URL for bytes loaded from the database, so the browser can show
/// or play them.
String? blobUrl(Uint8List bytes, String mime) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  return web.URL.createObjectURL(blob);
}

/// Absolute address for a link or a bundled `assets/...` file. Flutter web
/// serves bundled files under `<base href>/assets/`.
String absoluteUrl(String url) {
  if (!url.startsWith('assets/')) return url;
  return Uri.base.removeFragment().resolve('assets/$url').toString();
}
