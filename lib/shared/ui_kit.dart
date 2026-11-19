import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../cms/editable.dart';
import '../cms/site_content.dart';
import 'effects.dart';
import 'motion.dart';

/// Shared visual building blocks: image banners, stat tiles, photo cards and
/// dashboard sections, so every page follows the same structure.

const stockImages = (
  teamDiscussion: 'assets/images/stock/team_discussion.jpg',
  teamLaughing: 'assets/images/stock/team_laughing.jpg',
  collaboration: 'assets/images/stock/collaboration_top.jpg',
  coaching: 'assets/images/stock/coaching_conversation.jpg',
  facilitator: 'assets/images/stock/facilitator.jpg',
  meditation: 'assets/images/stock/meditation.jpg',
  balance: 'assets/images/stock/balance_stones.jpg',
  onlineLearning: 'assets/images/stock/online_learning.jpg',
  analytics: 'assets/images/stock/analytics.jpg',
  journal: 'assets/images/stock/journal.jpg',
  reflection: 'assets/images/stock/reflection.jpg',
  planning: 'assets/images/stock/planning.jpg',
  handshake: 'assets/images/stock/handshake.jpg',
  wellbeing: 'assets/images/stock/wellbeing_class.jpg',
  learner: 'assets/images/stock/learner.jpg',
  leadership: 'assets/images/stock/leadership.jpg',
  community: 'assets/images/stock/community.jpg',
);

/// Full-width photo banner with a brand gradient, used at the top of pages.
class ImageBanner extends StatelessWidget {
  const ImageBanner({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.height = 300,
    this.actions = const [],
  });
  final String image;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final double height;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final key = contentKey('banner', title);
    return CmsImage(
      '$key.image',
      image,
      label: 'banner photo',
      builder: (context, provider) => _banner(context, key, provider),
    );
  }

  Widget _banner(BuildContext context, String key, ImageProvider provider) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final banner = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: narrow ? height * 0.8 : height),
      decoration: BoxDecoration(
        image: DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Tok.brand.withValues(alpha: 0.94),
              Tok.brand.withValues(alpha: narrow ? 0.86 : 0.62),
              Tok.brandDeep.withValues(alpha: narrow ? 0.7 : 0.2),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 20 : 40,
                vertical: narrow ? 36 : 56,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Reveal(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 24, height: 2, color: Tok.accent),
                            const SizedBox(width: 10),
                            Flexible(
                              child: CmsValue(
                                '$key.eyebrow',
                                eyebrow,
                                label: 'banner label',
                                builder: (context, v) => Text(
                                  v.toUpperCase(),
                                  style: const TextStyle(
                                    color: Tok.accent,
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: const Duration(milliseconds: 90),
                        child: CmsText(
                          '$key.title',
                          title,
                          label: 'banner heading',
                          accent: Tok.accent,
                          style: Tok.heading(
                            narrow ? 30 : 42,
                            color: Colors.white,
                            height: 1.12,
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 14),
                        Reveal(
                          delay: const Duration(milliseconds: 180),
                          child: CmsText(
                            '$key.subtitle',
                            subtitle!,
                            label: 'banner intro',
                            multiline: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Wrap(spacing: 12, runSpacing: 12, children: actions),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (narrow) return banner;
    return Stack(
      children: [
        banner,
        Positioned(
          right: 48,
          top: 0,
          bottom: 0,
          child: Center(child: BrandOrnament(size: height * 0.78)),
        ),
      ],
    );
  }
}

/// Photo card with title, text and an optional link, for services/features.
class PhotoFeatureCard extends StatefulWidget {
  const PhotoFeatureCard({
    super.key,
    required this.image,
    required this.title,
    required this.text,
    this.icon,
    this.onTap,
    this.cta = 'Learn more',
    this.imageHeight = 170,
  });
  final String image;
  final String title;
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final String cta;
  final double imageHeight;

  @override
  State<PhotoFeatureCard> createState() => _PhotoFeatureCardState();
}

class _PhotoFeatureCardState extends State<PhotoFeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => TiltHover(
    maxTilt: 0.05,
    child: MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        decoration: BoxDecoration(
          color: Tok.surface,
          borderRadius: BorderRadius.circular(Tok.rLg),
          border: Border.all(color: _hover ? Tok.borderStrong : Tok.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: widget.imageHeight,
                      width: double.infinity,
                      child: ClipRect(
                        child: AnimatedScale(
                          scale: _hover && Motion.enabled(context) ? 1.04 : 1,
                          duration: Tok.base,
                          curve: Tok.easeOut,
                          child: Image.asset(
                            widget.image,
                            height: widget.imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            semanticLabel: widget.title,
                          ),
                        ),
                      ),
                    ),
                    if (widget.icon != null)
                      Positioned(
                        left: Tok.s4,
                        bottom: Tok.s3,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Tok.accent,
                            borderRadius: BorderRadius.circular(Tok.rMd),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Tok.brandDeep,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(Tok.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: Tok.heading(20)),
                      const SizedBox(height: Tok.s2),
                      Text(
                        widget.text,
                        style: const TextStyle(
                          height: 1.5,
                          color: Tok.textMuted,
                          fontSize: 15.5,
                        ),
                      ),
                      if (widget.onTap != null) ...[
                        const SizedBox(height: Tok.s4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.cta,
                                style: const TextStyle(
                                  fontFamily: Tok.display,
                                  color: Tok.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedSlide(
                              duration: Tok.base,
                              curve: Tok.easeOut,
                              offset: Offset(_hover ? 0.3 : 0, 0),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Tok.brand,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Key figure with an icon, used on every dashboard.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = Tok.brand,
    this.caption,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8DFFE)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: Tok.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Tok.brandDeep,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Tok.textMuted),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Lays out children in an even grid that collapses on narrow screens.
class TileGrid extends StatelessWidget {
  const TileGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.minTileWidth = 220,
    this.spacing = 16,
    this.minColumns = 1,
  });

  /// Keeps at least this many columns on phones (e.g. 2 for stat tiles).
  final int minColumns;
  final List<Widget> children;
  final int maxColumns;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = (box.maxWidth / minTileWidth).floor().clamp(
        box.maxWidth >= 300 ? minColumns : 1,
        maxColumns,
      );
      final w = (box.maxWidth - (cols - 1) * spacing) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

/// White panel with a title row, used for dashboard sections.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE8DFFE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: purple, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Tok.heading(18, color: Tok.brandDeep)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Tok.textMuted,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 16),
        // ListTiles inside need a Material for ink effects.
        Material(type: MaterialType.transparency, child: child),
      ],
    ),
  );
}

/// Greeting header for role dashboards: photo, greeting and quick actions.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.image,
    this.actions = const [],
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final String image;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final text = Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: softYellow,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Tok.heading(28, color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 15.5),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(color: Tok.brand),
        child: Stack(
          children: [
            const Positioned(
              left: -60,
              bottom: -70,
              child: Opacity(opacity: 0.7, child: BrandOrnament(size: 220)),
            ),
            wide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: text),
                        Expanded(
                          flex: 2,
                          child: ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [Colors.transparent, Colors.black],
                              stops: [0, 0.35],
                            ).createShader(r),
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(image, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  )
                : text,
          ],
        ),
      ),
    );
  }
}

/// Small pill button used in dark headers.
class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => Pop(child: _button());

  Widget _button() => primary
      ? FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Tok.accent,
            foregroundColor: Tok.brandDeep,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        )
      : OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
}

/// Large choice card for "I'm browsing as".
class PathChoiceCard extends StatefulWidget {
  const PathChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  State<PathChoiceCard> createState() => _PathChoiceCardState();
}

class _PathChoiceCardState extends State<PathChoiceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Pop(hoverScale: 1.03, child: _card());

  Widget _card() => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: _hover ? Colors.white : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Tok.rLg),
        border: Border.all(
          color: _hover ? Tok.accent : Colors.white.withValues(alpha: 0.28),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: softYellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: deepBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: Tok.display,
                          color: _hover ? Tok.brand : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: _hover ? Tok.textMuted : Colors.white,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: Tok.base,
                  curve: Tok.easeOut,
                  offset: Offset(_hover ? 0.25 : 0, 0),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _hover ? Tok.brand : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// One photo tile in a [BentoGrid]: full-bleed photo with a frosted caption
/// panel. The photo zooms slightly and the panel lifts on hover.
class BentoTile extends StatefulWidget {
  const BentoTile({
    super.key,
    required this.image,
    required this.icon,
    required this.title,
    required this.text,
    required this.cta,
    required this.onTap,
  });
  final String image;
  final IconData icon;
  final String title;
  final String text;
  final String cta;
  final VoidCallback onTap;

  @override
  State<BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<BentoTile> {
  bool _hover = false;
  String get _key => contentKey('tile', widget.title);

  @override
  Widget build(BuildContext context) {
    final motion = Motion.enabled(context);
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.text}. ${widget.cta}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tok.rLg + 4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: motion && _hover ? 1.05 : 1,
                  duration: Tok.slow,
                  curve: Tok.easeOut,
                  child: CmsImage(
                    '$_key.image',
                    widget.image,
                    label: 'tile photo',
                    builder: (context, p) => Image(image: p, fit: BoxFit.cover),
                  ),
                ),
                // Soft royal blue wash at the bottom so the panel reads.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Tok.brand.withValues(alpha: 0),
                        Tok.brandDeep.withValues(alpha: 0.45),
                      ],
                      stops: const [0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: Tok.s4,
                  right: Tok.s4,
                  bottom: Tok.s4,
                  child: AnimatedSlide(
                    offset: motion && _hover
                        ? const Offset(0, -0.04)
                        : Offset.zero,
                    duration: Tok.base,
                    curve: Tok.easeOut,
                    child: _FrostedPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Tok.accent,
                                  borderRadius: BorderRadius.circular(Tok.rSm),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: Tok.brand,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: Tok.s3),
                              Expanded(
                                child: CmsText(
                                  '$_key.title',
                                  widget.title,
                                  label: 'tile title',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Tok.heading(20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Tok.s2),
                          CmsText(
                            '$_key.text',
                            widget.text,
                            label: 'tile text',
                            multiline: true,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Tok.textMuted,
                              fontSize: 15.5,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: Tok.s3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.cta,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: Tok.display,
                                    color: Tok.brand,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AnimatedPadding(
                                duration: Tok.base,
                                curve: Tok.easeOut,
                                padding: EdgeInsets.only(
                                  left: motion && _hover ? 10 : 6,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Tok.brand,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostedPanel extends StatelessWidget {
  const _FrostedPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Tok.rLg),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.all(Tok.s4 + 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(Tok.rLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: child,
      ),
    ),
  );
}

/// Mixed-size photo grid: one large tile beside two stacked tiles on wide
/// screens, a large tile over a pair on tablets, and a single column on
/// phones.
class BentoGrid extends StatelessWidget {
  const BentoGrid({super.key, required this.tiles}) : assert(tiles.length == 3);
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final grow = (scale - 1).clamp(0.0, 1.0) * 160;
        if (w >= 900) {
          final h = 560.0 + grow;
          return SizedBox(
            height: h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: Reveal(child: tiles[0])),
                const SizedBox(width: Tok.s5),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Reveal(
                          delay: const Duration(milliseconds: 90),
                          child: tiles[1],
                        ),
                      ),
                      const SizedBox(height: Tok.s5),
                      Expanded(
                        child: Reveal(
                          delay: const Duration(milliseconds: 180),
                          child: tiles[2],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (w >= 600) {
          return Column(
            children: [
              SizedBox(
                height: 380 + grow,
                child: Reveal(child: tiles[0]),
              ),
              const SizedBox(height: Tok.s5),
              SizedBox(
                height: 340 + grow,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: Reveal(child: tiles[1])),
                    const SizedBox(width: Tok.s5),
                    Expanded(child: Reveal(child: tiles[2])),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            for (final (i, t) in tiles.indexed) ...[
              if (i > 0) const SizedBox(height: Tok.s4),
              SizedBox(
                height: 340 + grow,
                child: Reveal(child: t),
              ),
            ],
          ],
        );
      },
    );
  }
}
