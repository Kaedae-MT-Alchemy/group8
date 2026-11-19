import 'package:web/web.dart' as web;

/// The web build is never a widget-test run.
bool get runningInFlutterTest => false;

/// Reads the browser's `prefers-reduced-motion` setting directly, since
/// Flutter web does not always pass it through as disableAnimations.
bool get platformPrefersReducedMotion {
  try {
    return web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  } catch (_) {
    return false;
  }
}
