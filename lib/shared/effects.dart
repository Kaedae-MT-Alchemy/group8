import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'motion.dart';

/// Interactive effects: cursor ring, button pop, scroll progress, flip cards
/// and decorative brand graphics. Every moving piece checks
/// [Motion.enabled] so reduced-motion visitors get a still page.

// ---------------------------------------------------------------------------
// Cursor ring
// ---------------------------------------------------------------------------

/// A gold ring that trails the mouse and grows over anything clickable.
/// Mouse only: touch and stylus never show it.
class CursorHalo extends StatefulWidget {
  const CursorHalo({super.key, required this.child});
  final Widget child;

  @override
  State<CursorHalo> createState() => _CursorHaloState();
}

class _CursorHaloState extends State<CursorHalo>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _pos = ValueNotifier<Offset?>(null);
  final _ring = ValueNotifier<Offset>(Offset.zero);
  final _big = ValueNotifier<bool>(false);
  Offset _target = Offset.zero;

  void _tick(Duration _) {
    final d = _target - _ring.value;
    if (d.distance < 0.3) {
      _ring.value = _target;
      _ticker.stop();
      return;
    }
    _ring.value += d * 0.2;
  }

  void _onHover(PointerEvent e) {
    if (e.kind != PointerDeviceKind.mouse || !Motion.enabled(context)) {
      _pos.value = null;
      return;
    }
    if (_pos.value == null) _ring.value = e.position;
    _pos.value = e.position;
    _target = e.position;
    _big.value = _overClickable(e.position, e.viewId);
    if (!_ticker.isActive) _ticker.start();
  }

  bool _overClickable(Offset position, int viewId) {
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(result, position, viewId);
    for (final entry in result.path) {
      final Object target = entry.target;
      if (target is MouseTrackerAnnotation &&
          target.cursor == SystemMouseCursors.click) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pos.dispose();
    _ring.dispose();
    _big.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerHover: _onHover,
    onPointerMove: _onHover,
    child: MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onExit: (_) => _pos.value = null,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ValueListenableBuilder<Offset?>(
                  valueListenable: _pos,
                  builder: (context, pos, _) {
                    if (pos == null) return const SizedBox.shrink();
                    return Stack(
                      children: [
                        ValueListenableBuilder<Offset>(
                          valueListenable: _ring,
                          builder: (context, ring, _) =>
                              ValueListenableBuilder<bool>(
                                valueListenable: _big,
                                builder: (context, big, _) {
                                  final size = big ? 60.0 : 34.0;
                                  return Positioned(
                                    left: ring.dx - 30,
                                    top: ring.dy - 30,
                                    width: 60,
                                    height: 60,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: Tok.base,
                                        curve: Tok.easeOut,
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: big
                                              ? Tok.accent.withValues(
                                                  alpha: 0.18,
                                                )
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: Tok.accent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ),
                        Positioned(
                          left: pos.dx - 3,
                          top: pos.dy - 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Tok.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Button pop
// ---------------------------------------------------------------------------

/// Lifts and grows a control slightly on hover and squashes it on press,
/// with a small spring back. Wrap buttons and tappable cards.
class Pop extends StatefulWidget {
  const Pop({super.key, required this.child, this.hoverScale = 1.04});
  final Widget child;
  final double hoverScale;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = Motion.enabled(context);
    final scale = !on
        ? 1.0
        : _down
        ? 0.96
        : _hover
        ? widget.hoverScale
        : 1.0;
    return MouseRegion(
      opaque: false,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedSlide(
          offset: on && _hover && !_down ? const Offset(0, -0.04) : Offset.zero,
          duration: Tok.base,
          curve: Curves.easeOutBack,
          child: AnimatedScale(
            scale: scale,
            duration: _down ? const Duration(milliseconds: 90) : Tok.base,
            curve: _down ? Curves.easeOut : Curves.easeOutBack,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scroll progress
// ---------------------------------------------------------------------------

/// Thin gold bar across the top that fills as the page scrolls.
class ScrollProgress extends StatefulWidget {
  const ScrollProgress({super.key, required this.child});
  final Widget child;

  @override
  State<ScrollProgress> createState() => _ScrollProgressState();
}

class _ScrollProgressState extends State<ScrollProgress> {
  final _value = ValueNotifier<double>(0);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) {
          _update(n.metrics, n.depth);
          return false;
        },
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            _update(n.metrics, n.depth);
            return false;
          },
          child: Stack(
            children: [
              widget.child,
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 3,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _value,
                      builder: (context, v, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v,
                        child: const ColoredBox(color: Tok.accent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void _update(ScrollMetrics m, int depth) {
    if (depth != 0 || m.axis != Axis.vertical) return;
    final max = m.maxScrollExtent;
    _value.value = max <= 0 ? 0 : (m.pixels / max).clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// Flip card
// ---------------------------------------------------------------------------

/// Card that turns over on hover, focus or tap: name on the front, details
/// on the back. Under reduced motion it swaps faces without turning.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.icon,
    required this.title,
    required this.caption,
    required this.details,
    this.height = 240,
  });
  final IconData icon;
  final String title;
  final String caption;
  final String details;
  final double height;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> {
  bool _hover = false;
  bool _focus = false;
  bool _tapped = false;
  bool get _back => _hover || _focus || _tapped;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.enabled(context);
    return Semantics(
      container: true,
      label: '${widget.title}. ${widget.caption}. ${widget.details}',
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        child: GestureDetector(
          onTap: () => setState(() => _tapped = !_tapped),
          child: SizedBox(
            // Taller when the reader has a larger text size.
            height:
                widget.height *
                (MediaQuery.textScalerOf(context).scale(16).clamp(16, 32) / 16),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _back ? 1 : 0),
              duration: motion
                  ? const Duration(milliseconds: 650)
                  : Duration.zero,
              curve: Tok.easeInOut,
              builder: (context, t, _) {
                final showBack = t > 0.5;
                final angle = motion ? t * math.pi : 0.0;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  child: showBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(motion ? math.pi : 0),
                          child: _face(back: true),
                        )
                      : _face(back: false),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _face({required bool back}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Tok.s5),
    decoration: BoxDecoration(
      color: back ? Tok.brand : Tok.brandTint,
      borderRadius: BorderRadius.circular(Tok.rLg),
      border: Border.all(
        color: _focus ? Tok.brandDeep : Colors.transparent,
        width: 3,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -50,
          top: -50,
          child: ExcludeSemantics(
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _RingsPainter(
                color: back ? Tok.accent : Tok.surface,
                opacity: back ? 0.45 : 0.9,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!back) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Tok.accent,
                  borderRadius: BorderRadius.circular(Tok.rMd),
                ),
                child: Icon(widget.icon, color: Tok.brand, size: 22),
              ),
              const Spacer(),
            ],
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tok.heading(20, color: back ? Tok.accent : Tok.brand),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                back ? widget.details : widget.caption,
                maxLines: back ? 6 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: back ? Colors.white : Tok.textMuted,
                  fontSize: 15.5,
                  height: 1.45,
                ),
              ),
            ),
            if (!back) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.flip_rounded, size: 16, color: Tok.brand),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Hover or tap for details',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Tok.brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Brand graphics
// ---------------------------------------------------------------------------

/// Decorative brand ornament: a gold ring, soft lavender circles, a dot grid
/// and a four-point sparkle. Turns slowly when motion is on.
class BrandOrnament extends StatefulWidget {
  const BrandOrnament({super.key, this.size = 240, this.onDark = true});
  final double size;
  final bool onDark;

  @override
  State<BrandOrnament> createState() => _BrandOrnamentState();
}

class _BrandOrnamentState extends State<BrandOrnament>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
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
            size: Size.square(widget.size),
            painter: _OrnamentPainter(t: _c.value, onDark: widget.onDark),
          ),
        ),
      ),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter({required this.t, required this.onDark});
  final double t;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s * 0.55, s * 0.5);
    final spin = t * 2 * math.pi;
    // Soft lavender disc.
    canvas.drawCircle(
      c + Offset(s * 0.08, s * 0.1),
      s * 0.3,
      Paint()..color = Tok.brandTint.withValues(alpha: onDark ? 0.12 : 0.7),
    );
    // Dot grid.
    final dot = Paint()
      ..color = (onDark ? Colors.white : Tok.calm).withValues(alpha: 0.35);
    for (var x = 0; x < 5; x++) {
      for (var y = 0; y < 5; y++) {
        canvas.drawCircle(
          Offset(s * 0.06 + x * s * 0.06, s * 0.62 + y * s * 0.06),
          1.6,
          dot,
        );
      }
    }
    // Gold ring with a gap, turning.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: s * 0.36),
      spin,
      math.pi * 1.55,
      false,
      Paint()
        ..color = Tok.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Thin outer ring.
    canvas.drawCircle(
      c,
      s * 0.46,
      Paint()
        ..color = (onDark ? Colors.white : Tok.borderStrong).withValues(
          alpha: onDark ? 0.18 : 1,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Small gold planet on the outer ring.
    canvas.drawCircle(
      c + Offset(math.cos(-spin * 1.5), math.sin(-spin * 1.5)) * s * 0.46,
      5,
      Paint()..color = Tok.accent,
    );
    // Sparkle.
    final pulse = 0.85 + 0.15 * math.sin(spin * 3);
    _sparkle(canvas, Offset(s * 0.2, s * 0.22), s * 0.07 * pulse);
    _sparkle(canvas, Offset(s * 0.88, s * 0.86), s * 0.04 * (2 - pulse));
  }

  void _sparkle(Canvas canvas, Offset o, double r) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    canvas.drawPath(p, Paint()..color = Tok.accent);
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) =>
      old.t != t || old.onDark != onDark;
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.color, required this.opacity});
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final c = size.center(Offset.zero);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, size.width * 0.16 * i, p);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color || old.opacity != opacity;
}

/// Small gold sparkle that twinkles; used beside headings and badges.
class Sparkle extends StatefulWidget {
  const Sparkle({super.key, this.size = 18});
  final double size;

  @override
  State<Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<Sparkle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.enabled(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
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
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.rotate(
          angle: t * 0.5,
          child: Transform.scale(
            scale: 0.8 + t * 0.25,
            child: Icon(
              Icons.auto_awesome,
              size: widget.size,
              color: Tok.accent,
            ),
          ),
        );
      },
    ),
  );
}

/// A one-time greeting bubble that pops out of the chat button.
class PopInAfter extends StatefulWidget {
  const PopInAfter({
    super.key,
    required this.delay,
    required this.child,
    this.alignment = Alignment.bottomRight,
  });
  final Duration delay;
  final Widget child;
  final Alignment alignment;

  @override
  State<PopInAfter> createState() => _PopInAfterState();
}

class _PopInAfterState extends State<PopInAfter> {
  bool _shown = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (!Motion.allowed) return;
    _t = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _shown ? 1 : 0,
    alignment: widget.alignment,
    duration: Motion.enabled(context)
        ? const Duration(milliseconds: 450)
        : Duration.zero,
    curve: Curves.easeOutBack,
    child: widget.child,
  );
}

/// Soft gold pulse ring behind a round or pill control.
class PulseHalo extends StatefulWidget {
  const PulseHalo({super.key, required this.child});
  final Widget child;

  @override
  State<PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
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
    builder: (context, child) {
      final t = Curves.easeOut.transform((_c.value / 0.7).clamp(0.0, 1.0));
      return DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: [
            if (_c.isAnimating)
              BoxShadow(
                color: Tok.accent.withValues(alpha: 0.55 * (1 - t)),
                spreadRadius: 14 * t,
              ),
          ],
        ),
        child: child,
      );
    },
    child: widget.child,
  );
}

/// A glossy glass bubble: soft lavender body, white highlight and a gold
/// reflection on the rim. Decorative only.
class GlassBubble extends StatelessWidget {
  const GlassBubble({super.key, this.size = 150});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: const _BubblePainter(),
      ),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final rect = Rect.fromCircle(center: c, radius: r);
    // Body.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Tok.brandTint.withValues(alpha: 0.12),
            Tok.brand.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.22),
          ],
          stops: const [0, 0.45, 0.85, 1],
        ).createShader(rect),
    );
    // Rim.
    canvas.drawCircle(
      c,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    // Gold reflection on the lower right of the rim.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.86),
      0.15,
      1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Tok.accent.withValues(alpha: 0.85),
    );
    // Main highlight.
    canvas.save();
    canvas.translate(r * 0.62, r * 0.48);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(r * 1.02, r * 0.4),
      r * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}
