import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/channel.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/focus_card.dart';
import '../widgets/side_nav.dart';
import 'browse_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _section = 0;

  Widget _content(AppState s) {
    if (s.loading && s.channels.isEmpty) return const _LoadingView();
    if (s.error != null && s.channels.isEmpty) {
      return _ErrorView(message: s.error!, onRetry: s.refresh);
    }
    switch (_section) {
      case 1:
        return const BrowseView(key: ValueKey('all'), mode: BrowseMode.all);
      case 2:
        return const BrowseView(key: ValueKey('fav'), mode: BrowseMode.favorites);
      case 3:
        return const BrowseView(key: ValueKey('search'), mode: BrowseMode.search);
      case 4:
        return const SettingsView();
      default:
        return HomeFeed(onNavigateToSection: (idx) => setState(() => _section = idx));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: KeyedSubtree(key: ValueKey(_section), child: _content(s)),
    );

    return PopScope(
      canPop: _section == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _section = 0);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            if (wide)
              Row(
                children: [
                  SideNav(
                    selected: _section,
                    onSelect: (i) => setState(() => _section = i),
                  ),
                  Expanded(child: body),
                ],
              )
            else
              SafeArea(bottom: false, child: body),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.accent.withValues(alpha: 0.25),
                selectedIndex: _section,
                onDestinationSelected: (i) => setState(() => _section = i),
                destinations: [
                  for (final n in navItems)
                    NavigationDestination(icon: Icon(n.icon), label: n.label),
                ],
              ),
      ),
    );
  }
}

class HomeFeed extends StatelessWidget {
  final ValueChanged<int>? onNavigateToSection;
  const HomeFeed({super.key, this.onNavigateToSection});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final pad = EdgeInsets.symmetric(horizontal: narrow ? 20 : 48);
    final featured = s.featured;
    final recent = s.recentChannels;
    final favs = s.favoriteChannels;

    final pkChannels = s.channels.where((c) => c.country == 'PK').toList();
    final inChannels = s.channels.where((c) => c.country == 'IN').toList();

    void open(List<Channel> list, Channel c) => openPlayer(context, list, c);

    return ListView(
      padding: EdgeInsets.only(top: narrow ? 16 : 36, bottom: 64),
      children: [
        Padding(
          padding: pad,
          child: _Header(count: s.channels.length, refreshing: s.refreshing),
        ),
        SizedBox(height: narrow ? 20 : 28),
        if (featured != null)
          Padding(
            padding: pad,
            child: HeroBanner(
              channel: featured,
              resumed: recent.isNotEmpty,
              favorite: s.isFavorite(featured),
              onWatch: () => open(s.channels, featured),
              onFavorite: () => s.toggleFavorite(featured),
            ),
          ),
        SizedBox(height: narrow ? 20 : 28),
        // Agentic Smart Action Bar
        Padding(
          padding: pad,
          child: _AgenticDiscoveryChips(
            onSelectGroup: (group) {
              if (onNavigateToSection != null) onNavigateToSection!(1);
            },
          ),
        ),
        const SizedBox(height: 24),
        if (recent.isNotEmpty)
          ChannelRail(
            title: 'Continue Watching',
            channels: recent,
            padding: pad,
            isFavorite: s.isFavorite,
            onOpen: (c) => open(recent, c),
          ),
        if (favs.isNotEmpty)
          ChannelRail(
            title: 'Your Favorites',
            channels: favs,
            padding: pad,
            isFavorite: s.isFavorite,
            onOpen: (c) => open(favs, c),
          ),
        if (pkChannels.isNotEmpty)
          ChannelRail(
            title: '🇵🇰 Pakistan Premier HD',
            channels: pkChannels,
            padding: pad,
            isFavorite: s.isFavorite,
            onOpen: (c) => open(pkChannels, c),
          ),
        if (inChannels.isNotEmpty)
          ChannelRail(
            title: '🇮🇳 India Premier HD',
            channels: inChannels,
            padding: pad,
            isFavorite: s.isFavorite,
            onOpen: (c) => open(inChannels, c),
          ),
        for (final g in s.groups.take(10))
          Builder(
            builder: (_) {
              final list = s.byGroup(g);
              return ChannelRail(
                title: g,
                channels: list.take(40).toList(),
                padding: pad,
                isFavorite: s.isFavorite,
                onOpen: (c) => open(list, c),
              );
            },
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool refreshing;
  const _Header({required this.count, required this.refreshing});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showClock = w >= 660;
        final showEngineBadge = w >= 800;
        final showGreeting = w >= 480;
        final isVerySmall = w < 480;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PulseTvBrandLogo(size: 40, withText: w >= 360),
                      const SizedBox(width: 8),
                      const Spacer(),
                      if (showEngineBadge) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: AppColors.emerald),
                              SizedBox(width: 6),
                              Text(
                                '🇵🇰 PK & 🇮🇳 IN HD ENGINE ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (showGreeting)
                        Flexible(
                          child: Text(
                            _greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDim),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFD4DEFF)],
                        ).createShader(r),
                        child: Text(
                          '$count HD Channels Live',
                          style: TextStyle(
                            fontSize: isVerySmall ? 22 : (w < 600 ? 26 : 32),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (refreshing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.cyan),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (showClock) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const ClockText(
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Agentic Quick Filter Bar: intelligent category shortcuts.
class _AgenticDiscoveryChips extends StatelessWidget {
  final ValueChanged<String> onSelectGroup;
  const _AgenticDiscoveryChips({required this.onSelectGroup});

  @override
  Widget build(BuildContext context) {
    const chips = [
      ('🇵🇰 Pakistan HD', Icons.tv_rounded),
      ('🇮🇳 India HD', Icons.live_tv_rounded),
      ('⚡ 1080p Ultra', Icons.hd_rounded),
      ('📰 News Live', Icons.newspaper_rounded),
      ('⚽ Sports Live', Icons.sports_soccer_rounded),
      ('🎬 Cinema Hub', Icons.movie_filter_rounded),
      ('🎵 Music 24/7', Icons.music_note_rounded),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (label, icon) = chips[i];
          final isPK = i == 0;
          final isIN = i == 1;
          return FocusCard(
            onSelect: () => onSelectGroup(label),
            focusScale: 1.05,
            radius: BorderRadius.circular(100),
            builder: (context, focused) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: isPK
                      ? emeraldGradient
                      : isIN
                          ? const LinearGradient(colors: [Color(0xFFFF9933), Color(0xFFFF5277)])
                          : focused
                              ? cyberGradient
                              : null,
                  color: isPK || isIN || focused ? null : AppColors.surfaceHi.withValues(alpha: 0.85),
                  border: Border.all(
                    color: focused
                        ? Colors.white
                        : (isPK || isIN)
                            ? Colors.transparent
                            : AppColors.stroke,
                    width: focused ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isPK || isIN || focused ? FontWeight.w800 : FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Big cinematic agentic hero banner — flexible, zero-overflow, logo-first glass pedestal.
class HeroBanner extends StatelessWidget {
  final Channel channel;
  final bool resumed;
  final bool favorite;
  final VoidCallback onWatch;
  final VoidCallback onFavorite;

  const HeroBanner({
    super.key,
    required this.channel,
    required this.resumed,
    required this.favorite,
    required this.onWatch,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showFloatingLogo = w >= 660;
        final isCompact = w < 500;
        final contentPadding = showFloatingLogo
            ? (w < 820 ? const EdgeInsets.fromLTRB(32, 28, 200, 28) : const EdgeInsets.fromLTRB(44, 38, 280, 38))
            : EdgeInsets.all(isCompact ? 20 : 28);

        return Container(
          constraints: BoxConstraints(minHeight: isCompact ? 240 : (w < 720 ? 280 : 330)),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.strokeGlow),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF261A4E),
                Color(0xFF100E22),
                Color(0xFF1D0B24),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Blurred oversized logo as ambient background art
              Positioned(
                right: -60,
                top: -60,
                bottom: -60,
                child: Opacity(
                  opacity: 0.45,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: ChannelLogo(channel: channel, size: w < 720 ? 280 : 440),
                  ),
                ),
              ),
              // Deep dark gradient overlay for crystal readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Big logo floating frame on wide screens
              if (showFloatingLogo)
                Positioned(
                  right: w < 820 ? 28 : 56,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: w < 820 ? 150 : 200,
                      height: w < 820 ? 150 : 200,
                      padding: EdgeInsets.all(w < 820 ? 18 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(w < 820 ? 28 : 36),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.25),
                            blurRadius: 32,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ChannelLogo(channel: channel, size: w < 820 ? 108 : 144),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        LiveBadge(large: !isCompact),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            resumed ? 'RESUME STREAM' : 'AI FEATURED BROADCAST',
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                        Tag(channel.countryFlag, highlight: true),
                        Tag(channel.displayQuality),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      channel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 24 : (w < 720 ? 30 : 44),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [channel.countryFlag, channel.group, 'Zero-Jitter Ultra Low Latency'].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDim, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        PillButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Watch Now',
                          primary: true,
                          autofocus: showFloatingLogo,
                          onTap: onWatch,
                        ),
                        PillButton(
                          icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          label: favorite ? 'In Favorites' : 'Add to Favorites',
                          onTap: onFavorite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: agenticGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.stream_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              minHeight: 3.5,
              color: AppColors.cyan,
              backgroundColor: AppColors.surfaceHi,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tuning Pakistan & India HD Channels…',
            style: TextStyle(color: AppColors.textDim, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.live.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.live),
          ),
          const SizedBox(height: 18),
          const Text(
            'Couldn\'t Load Live Channels',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim),
            ),
          ),
          const SizedBox(height: 24),
          PillButton(
            icon: Icons.refresh_rounded,
            label: 'Retry Connection',
            primary: true,
            autofocus: true,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
