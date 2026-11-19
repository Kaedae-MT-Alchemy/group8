/// Platforms without dart:io or a browser: never a widget-test run.
bool get runningInFlutterTest => false;

/// No OS-level reduced-motion signal beyond MediaQuery here.
bool get platformPrefersReducedMotion => false;
