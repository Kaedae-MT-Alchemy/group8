export 'video_embed_stub.dart'
    if (dart.library.js_interop) 'video_embed_web.dart';

/// Returns the YouTube video ID in [url] (watch, youtu.be, embed or shorts
/// links), or null if it is not a YouTube link.
String? youTubeId(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.replaceFirst('www.', '').replaceFirst('m.', '');
  String? id;
  if (host == 'youtu.be') {
    id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
    id = uri.queryParameters['v'];
    if (id == null &&
        uri.pathSegments.length >= 2 &&
        {'embed', 'shorts', 'live'}.contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }
  return id != null && RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(id)
      ? id
      : null;
}
