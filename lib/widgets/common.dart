import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../theme.dart';
import 'focus_card.dart';

/// Channel logo with fast memory cache, low-latency rendering, and broadcast-grade fallback.
class ChannelLogo extends StatelessWidget {
  final Channel channel;
  final double size;
  const ChannelLogo({super.key, required this.channel, this.size = 64});

  @override
  Widget build(BuildContext context) {
    if (channel.logo.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: channel.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      memCacheWidth: (size * 2.5).round(),
      memCacheHeight: (size * 2.5).round(),
      maxWidthDiskCache: 400,
      maxHeightDiskCache: 400,
      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 60),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          color: Colors.white.withOpacity(0.04),
        ),
        child: SizedBox(
          width: size * 0.25,
          height: size * 0.25,
          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
        ),
      );

  Widget _fallback() {
    final isPK = channel.country == 'PK';
    final a = isPK ? const Color(0xFF01411C) : const Color(0xFFFF9933);
    final b = isPK ? const Color(0xFF00220F) : const Color(0xFF138808);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: LinearGradient(
          colors: [a, b],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: a.withOpacity(0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            channel.initials,
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              channel.displayQuality,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing live indicator with radar wave animation.
class LiveBadge extends StatefulWidget {
  final bool large;
  const LiveBadge({super.key, this.large = false});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final large = widget.large;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.live, Color(0xFFFF5277)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AppColors.live.withOpacity(0.55),
            blurRadius: large ? 16 : 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Container(
                width: large ? 8 : 6,
                height: large ? 8 : 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 4 + 4 * _ctrl.value,
                      spreadRadius: 1 * _ctrl.value,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: large ? 7 : 5),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: large ? 12 : 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass-style cyber tag for quality (1080p, 4K), country, category.
class Tag extends StatelessWidget {
  final String text;
  final bool highlight;
  const Tag(this.text, {super.key, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final isHD = text.contains('1080') || text.contains('4K') || text.toLowerCase() == 'hd';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHD
            ? AppColors.cyan.withOpacity(0.16)
            : highlight
                ? AppColors.accent.withOpacity(0.18)
                : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHD
              ? AppColors.cyan.withOpacity(0.6)
              : highlight
                  ? AppColors.accent.withOpacity(0.4)
                  : AppColors.stroke,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: isHD ? AppColors.cyan : AppColors.text,
        ),
      ),
    );
  }
}

/// Logo-First Channel Tile: The official broadcast logo is the hero element!
class ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final bool favorite;
  final bool autofocus;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.favorite = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    return FocusCard(
      autofocus: autofocus,
      onSelect: onTap,
      radius: BorderRadius.circular(22),
      builder: (context, focused) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: focused
                        ? [const Color(0xFF2E2460), const Color(0xFF16132D)]
                        : [AppColors.surfaceCard, AppColors.surface],
                  ),
                  border: Border.all(
                    color: focused ? AppColors.cyan : AppColors.stroke,
                    width: focused ? 2 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ambient glow on hover/focus
                    if (focused)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: RadialGradient(
                              colors: [
                                AppColors.cyan.withOpacity(0.18),
                                Colors.transparent,
                              ],
                              radius: 0.8,
                            ),
                          ),
                        ),
                      ),
                    // Centered Big Logo Hero
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ChannelLogo(
                          channel: channel,
                          size: narrow ? 92 : 110,
                        ),
                      ),
                    ),
                    // Top badges
                    const Positioned(top: 8, left: 8, child: LiveBadge()),
                    if (favorite)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent2.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.favorite_rounded, size: 14, color: AppColors.accent2),
                        ),
                      ),
                    // Bottom Badges: Country Flag & HD Resolution
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Tag(channel.countryFlag),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Tag(channel.displayQuality, highlight: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Minimalist subtitle showing group and subtle name on focus
            Row(
              children: [
                Expanded(
                  child: Text(
                    focused ? channel.name : '${channel.countryFlag} · ${channel.group}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
                      color: focused ? Colors.white : AppColors.textDim,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool autofocus;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      autofocus: autofocus,
      onSelect: onTap,
      focusScale: 1.05,
      radius: BorderRadius.circular(100),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: primary || focused
              ? agenticGradient
              : null,
          color: primary || focused ? null : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: focused
                ? Colors.white
                : (primary ? Colors.transparent : AppColors.stroke),
            width: focused ? 2 : 1,
          ),
          boxShadow: primary || focused
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChipButton({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      onSelect: onTap,
      focusScale: 1.05,
      glow: false,
      radius: BorderRadius.circular(100),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: selected
              ? cyberGradient
              : null,
          color: selected
              ? null
              : (focused ? Colors.white.withOpacity(0.18) : AppColors.surfaceHi),
          border: Border.all(
            color: focused
                ? AppColors.cyan
                : (selected ? Colors.transparent : AppColors.stroke),
            width: focused ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected || focused ? Colors.white : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

/// Live clock — updates every 15 s.
class ClockText extends StatefulWidget {
  final TextStyle? style;
  const ClockText({super.key, this.style});
  @override
  State<ClockText> createState() => _ClockTextState();
}

class _ClockTextState extends State<ClockText> {
  late Timer _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return Text(
      '$h:$m',
      style: widget.style ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    );
  }
}

/// Atmospheric cinematic glow behind everything with Agentic Nebula effects.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    Widget glow(Color c, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [c.withOpacity(0.18), c.withOpacity(0)],
            ),
          ),
        );
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
          Positioned(top: -260, right: -180, child: glow(AppColors.accent, 850)),
          Positioned(bottom: -320, left: -200, child: glow(AppColors.accent2, 750)),
          Positioned(top: 240, left: 160, child: glow(AppColors.cyan, 580)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                gradient: cyberGradient,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: AppColors.cyan.withOpacity(0.6), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Text(
                  trailing!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cyan),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Horizontal row of channel cards with generous heights and safe padding.
class ChannelRail extends StatelessWidget {
  final String title;
  final List<Channel> channels;
  final void Function(Channel c) onOpen;
  final bool Function(Channel c) isFavorite;
  final EdgeInsets padding;

  const ChannelRail({
    super.key,
    required this.title,
    required this.channels,
    required this.onOpen,
    required this.isFavorite,
    this.padding = const EdgeInsets.symmetric(horizontal: 48),
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final w = narrow ? 175.0 : 230.0;
    final h = narrow ? 150.0 : 190.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: padding,
          child: SectionTitle(title, trailing: '${channels.length}'),
        ),
        SizedBox(
          height: h + 44,
          child: FocusTraversalGroup(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: padding.copyWith(top: 14, bottom: 18),
              itemCount: channels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, i) => SizedBox(
                width: w,
                height: h,
                child: ChannelCard(
                  channel: channels[i],
                  favorite: isFavorite(channels[i]),
                  onTap: () => onOpen(channels[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
