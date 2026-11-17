import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

/// Inline YouTube player (privacy-enhanced mode) for the web build.
Widget? youTubePlayer(String videoId) {
  final viewType = 'youtube-$videoId';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final frame = web.HTMLIFrameElement()
        ..src =
            'https://www.youtube-nocookie.com/embed/$videoId?rel=0&modestbranding=1'
        ..title = 'Lesson video'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen'
        ..allowFullscreen = true;
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%';
      return frame;
    });
  }
  return HtmlElementView(viewType: viewType);
}
