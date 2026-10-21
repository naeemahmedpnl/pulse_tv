import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/playlist_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/focus_card.dart';
import 'intro_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(AppState s) {
    final url = _ctrl.text.trim();
    if (!url.startsWith('http') || s.sources.contains(url)) return;
    _ctrl.clear();
    s.setSources([...s.sources, url]);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final hPad = narrow ? 20.0 : 48.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, narrow ? 16 : 38, hPad, 60),
      children: [
        Text(
          'Settings & Sources',
          style: TextStyle(
            fontSize: narrow ? 28 : 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _Stat(label: 'Total Channels', value: '${s.channels.length}', icon: Icons.live_tv_rounded, accent: AppColors.cyan),
            _Stat(label: 'Categories', value: '${s.groups.length}', icon: Icons.grid_view_rounded, accent: AppColors.accent),
            _Stat(label: 'Favorites Saved', value: '${s.favorites.length}', icon: Icons.favorite_rounded, accent: AppColors.accent2),
            _Stat(label: 'Active Playlists', value: '${s.sources.length}', icon: Icons.playlist_play_rounded, accent: AppColors.emerald),
          ],
        ),
        const SizedBox(height: 36),
        const SectionTitle('Playlist Feeds (M3U / M3U8)'),
        const SizedBox(height: 8),
        const Text(
          'Add any public IPTV M3U playlist URL. Channels are automatically de-duplicated and indexed by the Agentic Engine.',
          style: TextStyle(color: AppColors.textDim, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 18),
        for (final url in s.sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SourceRow(
              url: url,
              onRemove: s.sources.length > 1
                  ? () => s.setSources(s.sources.where((u) => u != url).toList())
                  : null,
            ),
          ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 420;
            if (isVerySmall) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _add(s),
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/playlist.m3u',
                      prefixIcon: Icon(Icons.link_rounded, color: AppColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    icon: Icons.add_rounded,
                    label: 'Add Source',
                    primary: true,
                    onTap: () => _add(s),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _add(s),
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/playlist.m3u',
                      prefixIcon: Icon(Icons.link_rounded, color: AppColors.cyan),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                PillButton(
                  icon: Icons.add_rounded,
                  label: 'Add Source',
                  primary: true,
                  onTap: () => _add(s),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            PillButton(
              icon: Icons.refresh_rounded,
              label: s.refreshing ? 'Refreshing Engine…' : 'Reload Channels',
              primary: s.refreshing,
              onTap: s.refresh,
            ),
            PillButton(
              icon: Icons.restart_alt_rounded,
              label: 'Reset to Defaults',
              onTap: () => s.setSources(List.of(PlaylistService.defaultSources)),
            ),
            PillButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Replay Intro Tour',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => IntroScreen(onComplete: () => Navigator.pop(context))),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 38),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: AppColors.cyan, size: 24),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Stream Compliance & Legal Notice',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pulse TV aggregates public free-to-air broadcast feeds provided by the open IPTV community. '
                      'No subscription-gated or proprietary copyrighted materials are hosted by Pulse TV.',
                      style: TextStyle(color: AppColors.textDim, height: 1.4, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCard,
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String url;
  final VoidCallback? onRemove;
  const _SourceRow({required this.url, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.playlist_play_rounded, color: AppColors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Verified Active Feed · Auto-Synchronized',
                  style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            FocusCard(
              onSelect: onRemove!,
              glow: false,
              radius: BorderRadius.circular(10),
              builder: (_, f) => AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: f ? AppColors.live : Colors.white.withValues(alpha: 0.06),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: f ? Colors.white : AppColors.textDim,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
