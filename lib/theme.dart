import 'package:flutter/material.dart';

/// Alchemy Lavender design tokens. See DESIGN.md for the rules behind each value.
abstract final class Tok {
  // Colour: semantic names (primitives noted alongside). Palette set by
  // the course lecturer: royal blue, Alchemy gold, lavenders, caption purple.
  static const brand = Color(0xFF2412B8); // royal blue (main colour)
  static const brandHover = Color(0xFF1C0E94); // royal blue, pressed
  static const brandDeep = Color(0xFF16105B); // deep navy (footer, dark text)
  static const brandTint = Color(0xFFE8DFFE); // soft lavender
  static const accent = Color(0xFFFCC931); // Alchemy gold
  static const accentTint = Color(0xFFFFF4CC); // gold, 20%
  static const onAccentTint = Color(0xFF6B4E00); // text on gold tint
  static const calm = Color(0xFF7B6FD0); // lavender mid (progress, graphics)
  static const calmText = Color(0xFF47416F); // caption purple
  static const calmTint = Color(0xFFEFEAFE); // lavender tag fill
  static const page = Color(0xFFF7F5FF); // pale lavender
  static const surface = Colors.white; // pure white
  static const text = Color(0xFF1B1838); // ink
  static const textMuted = Color(0xFF47416F); // caption purple
  static const border = Color(0xFFE8DFFE); // soft lavender
  static const borderStrong = Color(0xFFD3C8F5);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFB3261E);

  // Type families.
  static const display = 'Lexend';
  static const serif = 'Fraunces'; // big headings only (28px and up)
  static const body = 'SourceSans3';

  // Spacing (4-pt scale).
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
  static const s8 = 64.0;
  static const s9 = 96.0;

  // Radius.
  static const rSm = 8.0;
  static const rMd = 12.0;
  static const rLg = 20.0;
  static const rPill = 999.0;

  // Elevation: only on hover.
  static const shadowHover = [
    BoxShadow(color: Color(0x1F2412B8), blurRadius: 40, offset: Offset(0, 16)),
  ];

  // Motion.
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const reveal = Duration(milliseconds: 520);
  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;

  /// Heading style helper: Fraunces serif for big headings (28px and up),
  /// Lexend for card and list titles.
  static TextStyle heading(
    double size, {
    Color color = brand,
    double? height,
  }) => size >= 28
      ? TextStyle(
          fontFamily: serif,
          fontSize: size * 1.04,
          height: height ?? (size >= 36 ? 1.1 : 1.2),
          fontWeight: FontWeight.w500,
          letterSpacing: size >= 36 ? -0.8 : -0.4,
          color: color,
        )
      : TextStyle(
          fontFamily: display,
          fontSize: size,
          height: height ?? 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: color,
        );

  /// Italic accent for one or two words inside a serif heading.
  static TextStyle accentItalic(TextStyle base, {Color? color}) =>
      base.copyWith(fontStyle: FontStyle.italic, color: color);
}

// Legacy names used across the codebase, mapped onto Alchemy Lavender tokens.
const deepBlue = Tok.brandDeep;
const royalBlue = Tok.brand;
const softYellow = Tok.accent;
const purple = Tok.calmText;
const ink = Tok.text;
const canvas = Tok.page;

ThemeData buildTheme() {
  const focusRing = BorderSide(color: Tok.brandDeep, width: 3);
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: Tok.body,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Tok.brand,
      primary: Tok.brand,
      onPrimary: Colors.white,
      secondary: Tok.calmText,
      tertiary: Tok.accent,
      surface: Tok.surface,
      onSurface: Tok.text,
      onSurfaceVariant: Tok.textMuted,
      outline: Tok.borderStrong,
      outlineVariant: Tok.border,
      error: Tok.danger,
    ),
  );
  final buttonText = const TextStyle(
    fontFamily: Tok.display,
    fontWeight: FontWeight.w600,
    fontSize: 15.5,
    letterSpacing: 0,
  );
  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const FadePageTransitionsBuilder(),
      },
    ),
    scaffoldBackgroundColor: Tok.page,
    dividerTheme: const DividerThemeData(color: Tok.border, thickness: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Tok.page,
      foregroundColor: Tok.brand,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: Tok.border)),
    ),
    textTheme: base.textTheme
        .apply(
          fontFamily: Tok.body,
          bodyColor: Tok.text,
          displayColor: Tok.brand,
        )
        .copyWith(
          displayLarge: Tok.heading(56, height: 1.05),
          displayMedium: Tok.heading(44),
          displaySmall: Tok.heading(36),
          headlineLarge: Tok.heading(40, height: 1.12),
          headlineMedium: Tok.heading(30, height: 1.2),
          headlineSmall: Tok.heading(24),
          titleLarge: Tok.heading(20),
          titleMedium: const TextStyle(
            fontFamily: Tok.display,
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            color: Tok.text,
          ),
          bodyLarge: const TextStyle(
            fontFamily: Tok.body,
            fontSize: 18,
            height: 1.6,
            color: Tok.textMuted,
          ),
          bodyMedium: const TextStyle(
            fontFamily: Tok.body,
            fontSize: 16,
            height: 1.55,
            color: Tok.text,
          ),
          bodySmall: const TextStyle(
            fontFamily: Tok.body,
            fontSize: 14,
            height: 1.45,
            color: Tok.textMuted,
          ),
          labelLarge: buttonText,
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        textStyle: WidgetStatePropertyAll(buttonText),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Tok.rMd)),
          ),
        ),
        side: const WidgetStateProperty<BorderSide?>.fromMap({
          WidgetState.focused: focusRing,
        }),
        // Buttons pop: a soft royal-blue shadow appears on hover.
        elevation: const WidgetStateProperty<double?>.fromMap({
          WidgetState.pressed: 0,
          WidgetState.hovered: 6,
          WidgetState.any: 0,
        }),
        shadowColor: const WidgetStatePropertyAll(Color(0x552412B8)),
        animationDuration: Tok.base,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        textStyle: WidgetStatePropertyAll(buttonText),
        foregroundColor: const WidgetStatePropertyAll(Tok.brand),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Tok.rMd)),
          ),
        ),
        side: const WidgetStateProperty<BorderSide?>.fromMap({
          WidgetState.focused: focusRing,
          WidgetState.any: BorderSide(color: Tok.brand, width: 1.5),
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        foregroundColor: const WidgetStatePropertyAll(Tok.brand),
        textStyle: WidgetStatePropertyAll(
          buttonText.copyWith(fontWeight: FontWeight.w500),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Tok.rSm)),
          ),
        ),
        side: const WidgetStateProperty<BorderSide?>.fromMap({
          WidgetState.focused: focusRing,
        }),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(44, 44))),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Tok.surface,
      selectedColor: Tok.brandTint,
      side: const BorderSide(color: Tok.border),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(fontFamily: Tok.body, color: Tok.text),
    ),
    cardTheme: const CardThemeData(
      color: Tok.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Tok.rLg)),
        side: BorderSide(color: Tok.border),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Tok.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Tok.rMd)),
        borderSide: BorderSide(color: Tok.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Tok.rMd)),
        borderSide: BorderSide(color: Tok.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Tok.rMd)),
        borderSide: BorderSide(color: Tok.brand, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Tok.calm,
      linearTrackColor: Tok.calmTint,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Tok.brand,
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: Tok.text,
        borderRadius: BorderRadius.all(Radius.circular(Tok.rSm)),
      ),
    ),
  );
}

/// Soft fade + small rise between pages.
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Tok.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
