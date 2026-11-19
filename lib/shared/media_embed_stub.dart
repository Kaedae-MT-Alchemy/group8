import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Non-web builds have no embedded viewers; callers show open/download.
Widget? iframeView(String url, {String title = 'Document'}) => null;

/// Non-web builds have no inline video element.
Widget? videoView(String url) => null;

/// Object URL for in-memory bytes (web only).
String? blobUrl(Uint8List bytes, String mime) => null;

/// Absolute address for a link or a bundled `assets/...` file.
String absoluteUrl(String url) => url;
