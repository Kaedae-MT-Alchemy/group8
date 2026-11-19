import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'test_env_stub.dart'
    if (dart.library.io) 'test_env_io.dart'
    if (dart.library.js_interop) 'test_env_web.dart';

/// Motion helpers for Calm Ink (see DESIGN.md §6).
///
/// Every looping or delayed animation checks [Motion.enabled] first, so the
/// site stays still for people who ask their device for reduced motion.
abstract final class Motion {
  /// Set to false to freeze all decorative motion (used by tests).
  static bool allowed = !runningInFlutterTest;

  static final bool _osReduced = platformPrefersReducedMotion;

  static bool enabled(BuildContext context) =>
      allowed &&
      !_osReduced &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}

/// Calls [onVisible] once, the first time the widget scrolls into view.
mixin _OnFirstVisible<T extends StatefulWidget> on State<T> {
  bool seen = false;
  ScrollPosition? _position;

  void onVisible();

  /// Fraction of the viewport height the top edge must pass.
  double get threshold => 0.92;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (seen) return;
    if (!Motion.enabled(context)) {
      seen = true;
      onVisible();
      return;
    }
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (seen || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.sizeOf(context).height;
    if (top < screen * threshold && top + box.size.height > 0) {
      seen = true;
      _position?.removeListener(_check);
      onVisible();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }
}

/// Fades and rises its child 24px the first time it scrolls into view.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 24,
  });
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with _OnFirstVisible<Reveal> {
  bool _shown = false;
  Timer? _timer;

  @override
  void onVisible() {
    if (!Motion.enabled(context) || widget.delay == Duration.zero) {
      if (mounted) setState(() => _shown = true);
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Motion.allowed) return widget.child;
    if (!Motion.enabled(context)) {
      // Reduced motion: keep a gentle fade, drop the movement.
      return AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: Tok.base,
        curve: Tok.easeOut,
        child: widget.child,
      );
    }
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: Tok.reveal,
      curve: Tok.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : Offset(0, widget.offset / 400),
        duration: Tok.reveal,
        curve: Tok.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Counts a stat like "1,100+" up from zero when it scrolls into view.
class CountUp extends StatefulWidget {
  const CountUp(this.value, {super.key, required this.style});
  final String value;
  final TextStyle style;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with _OnFirstVisible<CountUp> {
  bool _go = false;

  @override
  void onVisible() {
    if (mounted) setState(() => _go = true);
  }

  static String _format(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^([^\d]*)([\d,]+)(.*)$').firstMatch(widget.value);
    final target = int.tryParse(match?.group(2)?.replaceAll(',', '') ?? '');
    if (match == null || target == null || !Motion.enabled(context)) {
      return Text(widget.value, style: widget.style);
    }
    return Semantics(
      label: widget.value,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _go ? target.toDouble() : 0),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutQuart,
        builder: (context, v, _) => Text(
          '${match.group(1)}${_format(v.round())}${match.group(3)}',
          style: widget.style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Tilts toward the pointer and lifts on hover. Touch and reduced motion get
/// a plain card.
class TiltHover extends StatefulWidget {
  const TiltHover({
    super.key,
    required this.child,
    this.maxTilt = 0.06,
    this.lift = 6,
    this.radius = Tok.rLg,
  });
  final Widget child;
  final double maxTilt;
  final double lift;
  final double radius;

  @override
  State<TiltHover> createState() => _TiltHoverState();
}

class _TiltHoverState extends State<TiltHover> {
  Offset _tilt = Offset.zero;
  bool _hover = false;

  void _move(PointerEvent e) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final dx = (e.localPosition.dx / size.width - 0.5) * 2;
    final dy = (e.localPosition.dy / size.height - 0.5) * 2;
    setState(() => _tilt = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1)));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = Motion.enabled(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onHover: enabled ? _move : null,
      onExit: (_) => setState(() {
        _hover = false;
        _tilt = Offset.zero;
      }),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: enabled ? _tilt : Offset.zero),
        duration: Tok.base,
        curve: Tok.easeOut,
        builder: (context, t, child) => AnimatedContainer(
          duration: Tok.base,
          curve: Tok.easeOut,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..translateByDouble(0.0, _hover ? -widget.lift : 0.0, 0.0, 1.0)
            ..rotateX(-t.dy * widget.maxTilt)
            ..rotateY(t.dx * widget.maxTilt),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _hover ? Tok.shadowHover : const [],
          ),
          child: Stack(
            children: [
              child!,
              // Soft gold light that follows the cursor across the card.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: enabled && _hover ? 1 : 0,
                    duration: Tok.base,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.radius),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(t.dx, t.dy),
                            radius: 0.9,
                            colors: [
                              Tok.accent.withValues(alpha: 0.22),
                              Tok.accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// A row of equally sized items that glides sideways forever. Pauses on hover
/// and stays still under reduced motion (then it scrolls by hand).
class Marquee extends StatefulWidget {
  const Marquee({
    super.key,
    required this.children,
    required this.itemWidth,
    required this.height,
    this.gap = 16,
    this.pixelsPerSecond = 30,
  });
  final List<Widget> children;
  final double itemWidth;
  final double height;
  final double gap;
  final double pixelsPerSecond;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  double get _loop => widget.children.length * (widget.itemWidth + widget.gap);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: math.max(
          1,
          (_loop / widget.pixelsPerSecond * 1000).round(),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.enabled(context) && widget.children.isNotEmpty) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _row() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final child in widget.children)
        Padding(
          padding: EdgeInsets.only(right: widget.gap),
          child: SizedBox(
            width: widget.itemWidth,
            height: widget.height,
            child: child,
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    if (!Motion.enabled(context)) {
      return SizedBox(
        height: widget.height,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _row(),
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => _c.stop(),
      onExit: (_) => _c.repeat(),
      child: SizedBox(
        height: widget.height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_c.value * _loop, 0),
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_row(), _row(), _row()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft, slowly drifting circles behind a dark hero. Purely decorative.
class AmbientShapes extends StatefulWidget {
  const AmbientShapes({super.key});

  @override
  State<AmbientShapes> createState() => _AmbientShapesState();
}

class _AmbientShapesState extends State<AmbientShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.enabled(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ShapesPainter(_c.value),
            size: Size.infinite,
          ),
        ),
      ),
    ),
  );
}

class _ShapesPainter extends CustomPainter {
  _ShapesPainter(this.t);
  final double t;

  static const _blobs = [
    // x, y (fractions), radius (fraction of shortest side), colour, phase
    (0.82, 0.18, 0.55, Color(0x40FCC931), 0.0), // Alchemy gold
    (0.12, 0.85, 0.65, Color(0x40E8DFFE), 0.33), // soft lavender
    (0.55, 0.65, 0.40, Color(0x3316105B), 0.66), // deep navy
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    for (final (x, y, r, color, phase) in _blobs) {
      final a = (t + phase) * 2 * math.pi;
      final center = Offset(
        size.width * x + math.cos(a) * s * 0.06,
        size.height * y + math.sin(a * 2) * s * 0.04,
      );
      final radius = s * r * (1 + 0.05 * math.sin(a));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
    // Fine dotted grid, a quiet nod to structure and growth.
    final dot = Paint()..color = const Color(0x14FFFFFF);
    for (double gx = 24; gx < size.width; gx += 32) {
      for (double gy = 24; gy < size.height; gy += 32) {
        canvas.drawCircle(Offset(gx, gy), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_ShapesPainter old) => old.t != t;
}

/// Cycles through [words] in place, sliding each new one up.
class RotatingWords extends StatefulWidget {
  const RotatingWords({
    super.key,
    required this.words,
    required this.style,
    this.every = const Duration(milliseconds: 2600),
  });
  final List<String> words;
  final TextStyle style;
  final Duration every;

  @override
  State<RotatingWords> createState() => _RotatingWordsState();
}

class _RotatingWordsState extends State<RotatingWords> {
  int _i = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (Motion.enabled(context) && widget.words.length > 1) {
      _timer = Timer.periodic(widget.every, (_) {
        if (mounted) setState(() => _i = (_i + 1) % widget.words.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Tok.slow,
    switchInCurve: Tok.easeOut,
    switchOutCurve: Tok.easeOut,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, anim) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.45),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    ),
    child: Text(widget.words[_i], key: ValueKey(_i), style: widget.style),
  );
}

/// Gentle up-and-down float for small badges.
class FloatY extends StatefulWidget {
  const FloatY({super.key, required this.child, this.phase = 0, this.amp = 6});
  final Widget child;
  final double phase;
  final double amp;

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.enabled(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amp,
      ),
      child: child,
    ),
    child: widget.child,
  );
}
