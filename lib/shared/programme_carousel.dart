import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../cms/editable.dart';
import '../cms/site_content.dart';
import 'effects.dart';
import 'motion.dart';

/// One card on the programme wheel.
class ProgrammeItem {
  const ProgrammeItem({
    required this.title,
    required this.text,
    required this.image,
    required this.icon,
    required this.onOpen,
    this.tag,
  });
  final String title;
  final String text;
  final String image;
  final IconData icon;
  final VoidCallback onOpen;
  final String? tag;
}

/// Programme cards on a slowly turning 3D wheel. The front card is the one
/// you can open; the others rotate to the front when tapped.
///
/// Auto-advances every [interval], pauses on hover, focus or the pause
/// button, and only moves by hand under reduced motion.
class ProgrammeCarousel extends StatefulWidget {
  const ProgrammeCarousel({
    super.key,
    required this.items,
    this.interval = const Duration(milliseconds: 4500),
  });
  final List<ProgrammeItem> items;
  final Duration interval;

  @override
  State<ProgrammeCarousel> createState() => _ProgrammeCarouselState();
}

class _ProgrammeCarouselState extends State<ProgrammeCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
  );
  int _target = 0;
  Timer? _timer;
  bool _hovering = false;
  bool _focused = false;
  bool _paused = false;
  double _dragStart = 0;

  int get _n => widget.items.length;
  int get _current => _n == 0 ? 0 : _target % _n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!mounted || _n < 2 || !Motion.enabled(context)) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!_hovering && !_focused && !_paused) _go(_target + 1);
    });
  }

  void _go(int target) {
    if (_n == 0) return;
    setState(() => _target = target);
    if (Motion.enabled(context)) {
      _pos.animateTo(
        target.toDouble(),
        duration: Tok.slow + const Duration(milliseconds: 80),
        curve: Tok.easeInOut,
      );
    } else {
      _pos.value = target.toDouble();
    }
  }

  void _goTo(int index) {
    // Shortest way round the wheel.
    var delta = (index - _current) % _n;
    if (delta > _n / 2) delta -= _n;
    _go(_target + delta);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_n == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('Programmes will appear here soon.'),
      );
    }
    final motion = Motion.enabled(context);
    return LayoutBuilder(
      builder: (context, box) {
        final cardW = math.min(340.0, box.maxWidth * 0.78);
        final spread = math.min(cardW * 0.72, box.maxWidth / 3.4);
        // Cards grow with the reader's text size so nothing gets cut off.
        final textScale =
            MediaQuery.textScalerOf(context).scale(16).clamp(16, 32) / 16;
        final cardH = 440.0 + (textScale - 1) * 300;
        return Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          onKeyEvent: (node, e) {
            if (e is! KeyDownEvent) return KeyEventResult.ignored;
            if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
              _go(_target + 1);
              return KeyEventResult.handled;
            }
            if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _go(_target - 1);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            children: [
              MouseRegion(
                onEnter: (_) => _hovering = true,
                onExit: (_) => _hovering = false,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (d) =>
                      _dragStart = d.globalPosition.dx,
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v.abs() > 200) {
                      _go(_target + (v < 0 ? 1 : -1));
                    }
                  },
                  onHorizontalDragUpdate: (d) {
                    if ((d.globalPosition.dx - _dragStart).abs() > 80) {
                      _go(
                        _target + (d.globalPosition.dx < _dragStart ? 1 : -1),
                      );
                      _dragStart = d.globalPosition.dx;
                    }
                  },
                  child: SizedBox(
                    height: cardH + 24,
                    child: AnimatedBuilder(
                      animation: _pos,
                      builder: (context, _) {
                        final p = _pos.value;
                        final cards = <(double, Widget)>[];
                        for (var i = 0; i < _n; i++) {
                          var d = (i - p) % _n;
                          if (d > _n / 2) d -= _n;
                          final ad = d.abs();
                          if (ad > 2.6) continue;
                          final scale = 1 - math.min(ad, 2.5) * 0.12;
                          final opacity = (1 - ad * 0.32).clamp(0.0, 1.0);
                          final front = ad < 0.5;
                          cards.add((
                            ad,
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, motion ? 0.0011 : 0)
                                ..translateByDouble(d * spread, ad * 10, 0, 1)
                                ..rotateY(motion ? -d * 0.38 : 0)
                                ..scaleByDouble(scale, scale, 1, 1),
                              child: Opacity(
                                opacity: opacity,
                                child: ExcludeSemantics(
                                  excluding: !front,
                                  child: _ProgrammeCard(
                                    item: widget.items[i],
                                    width: cardW,
                                    height: cardH,
                                    front: front,
                                    onTap: front
                                        ? widget.items[i].onOpen
                                        : () => _goTo(i),
                                  ),
                                ),
                              ),
                            ),
                          ));
                        }
                        cards.sort((a, b) => b.$1.compareTo(a.$1));
                        return Stack(
                          alignment: Alignment.center,
                          children: [for (final c in cards) c.$2],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Tok.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Previous programme',
                    onPressed: () => _go(_target - 1),
                  ),
                  const SizedBox(width: Tok.s3),
                  for (var i = 0; i < _n; i++)
                    Semantics(
                      button: true,
                      selected: i == _current,
                      label: 'Show ${widget.items[i].title}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Tok.rPill),
                        onTap: () => _goTo(i),
                        child: SizedBox(
                          width: 24,
                          height: 44,
                          child: Center(
                            child: AnimatedContainer(
                              duration: Tok.base,
                              curve: Tok.easeOut,
                              width: i == _current ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _current
                                    ? Tok.brand
                                    : Tok.borderStrong,
                                borderRadius: BorderRadius.circular(Tok.rPill),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: Tok.s3),
                  _RoundButton(
                    icon: Icons.arrow_forward_rounded,
                    tooltip: 'Next programme',
                    onPressed: () => _go(_target + 1),
                  ),
                  if (motion) ...[
                    const SizedBox(width: Tok.s2),
                    _RoundButton(
                      icon: _paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      tooltip: _paused ? 'Play carousel' : 'Pause carousel',
                      onPressed: () => setState(() => _paused = !_paused),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Pop(
    hoverScale: 1.08,
    child: IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: Tok.brand,
        side: const BorderSide(color: Tok.borderStrong),
        backgroundColor: Tok.surface,
        minimumSize: const Size(44, 44),
      ),
    ),
  );
}

class _ProgrammeCard extends StatelessWidget {
  const _ProgrammeCard({
    required this.item,
    required this.width,
    required this.height,
    required this.front,
    required this.onTap,
  });
  final ProgrammeItem item;
  final double width;
  final double height;
  final bool front;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Material(
      color: Tok.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tok.rLg),
        side: BorderSide(color: front ? Tok.borderStrong : Tok.border),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: front ? 10 : 2,
      shadowColor: const Color(0x3316105B),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SiteImage(
                  '${contentKey('programme', item.title)}.image',
                  item.image,
                  height: height * 0.46,
                  width: double.infinity,
                  semanticLabel: item.title,
                ),
                Positioned(
                  left: Tok.s4,
                  bottom: Tok.s4,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Tok.accent,
                      borderRadius: BorderRadius.circular(Tok.rMd),
                    ),
                    child: Icon(item.icon, color: Tok.brand, size: 22),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tok.s5,
                  Tok.s4,
                  Tok.s5,
                  Tok.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.tag != null) ...[
                      Text(
                        item.tag!.toUpperCase(),
                        style: const TextStyle(
                          color: Tok.calmText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Tok.heading(21),
                    ),
                    const SizedBox(height: Tok.s2),
                    Expanded(
                      child: Text(
                        item.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Tok.textMuted,
                          height: 1.5,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: Tok.base,
                      opacity: front ? 1 : 0,
                      child: const Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Explore programme',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: Tok.display,
                                color: Tok.brandHover,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Tok.brandHover,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
