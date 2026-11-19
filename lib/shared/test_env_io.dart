import 'dart:io' show Platform;

/// True under `flutter test`, where looping animations would stop
/// `pumpAndSettle` from ever settling.
bool get runningInFlutterTest =>
    Platform.environment.containsKey('FLUTTER_TEST');

/// Desktop and mobile builds rely on MediaQuery.disableAnimations.
bool get platformPrefersReducedMotion => false;
