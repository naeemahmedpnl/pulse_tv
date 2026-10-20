import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/channel.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

enum BrowseMode { all, favorites, search }

/// Grid browser used for Live TV (with category and country chips), Favorites and Search.
class BrowseView extends StatefulWidget {
  final BrowseMode mode;
  const BrowseView({super.key, required this.mode});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  String? _group;
  String? _countryFilter; // 'PK', 'IN', or null
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final hPad = narrow ? 20.0 : 48.0;

    List<Channel> list;
    if (widget.mode == BrowseMode.favorites) {
      list = s.favoriteChannels;
    } else if (widget.mode == BrowseMode.search) {
      list = s.search(_query);
    } else {
      list = s.channels;
      if (_countryFilter != null) {
        list = list.where((c) => c.country == _countryFilter).toList();
      }
      if (_group != null) {
        list = list.where((c) => c.group == _group).toList();
      }
    }

    final title = switch (widget.mode) {
      BrowseMode.favorites => 'Your Favorites',
      BrowseMode.search => 'Search Live TV',
      BrowseMode.all => _countryFilter == 'PK'
          ? '🇵🇰 Pakistan Live TV'
          : _countryFilter == 'IN'
              ? '🇮🇳 India Live TV'
              : _group ?? 'All Channels',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, narrow ? 16 : 38, hPad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: narrow ? 28 : 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHi,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${list.length} Channels',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.mode == BrowseMode.search)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search Pakistan, India channels, categories (News, Sports)…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cyan),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textDim),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        if (widget.mode == BrowseMode.all)
          SizedBox(
            height: 74,
            child: FocusTraversalGroup(
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 8),
                children: [
                  ChipButton(
                    label: '✦ All Channels',
                    selected: _countryFilter == null && _group == null,
                    onTap: () => setState(() {
                      _countryFilter = null;
                      _group = null;
                    }),
                  ),
                  const SizedBox(width: 10),
                  ChipButton(
                    label: '🇵🇰 Pakistan HD',
                    selected: _countryFilter == 'PK',
                    onTap: () => setState(() {
                      _countryFilter = _countryFilter == 'PK' ? null : 'PK';
                      _group = null;
                    }),
                  ),
                  const SizedBox(width: 10),
                  ChipButton(
                    label: '🇮🇳 India HD',
                    selected: _countryFilter == 'IN',
                    onTap: () => setState(() {
                      _countryFilter = _countryFilter == 'IN' ? null : 'IN';
                      _group = null;
                    }),
                  ),
                  for (final g in s.groups) ...[
                    const SizedBox(width: 10),
                    ChipButton(
                      label: g,
                      selected: _group == g && _countryFilter == null,
                      onTap: () => setState(() {
                        _group = g;
                        _countryFilter = null;
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? _Empty(mode: widget.mode)
              : FocusTraversalGroup(
                  child: GridView.builder(
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 60),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: narrow ? 180 : 250,
                      mainAxisExtent: narrow ? 160 : 200,
                      crossAxisSpacing: 22,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => ChannelCard(
                      channel: list[i],
                      favorite: s.isFavorite(list[i]),
                      onTap: () => openPlayer(context, list, list[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final BrowseMode mode;
  const _Empty({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub) = switch (mode) {
      BrowseMode.favorites => (
          Icons.favorite_border_rounded,
          'No Favorites Saved Yet',
          'Open any channel in fullscreen and tap the heart icon to add it here.'
        ),
      BrowseMode.search => (
          Icons.search_off_rounded,
          'No Matching Channels Found',
          'Try typing another keyword, genre, or country code.'
        ),
      BrowseMode.all => (
          Icons.live_tv_rounded,
          'No Channels in this Category',
          'Select another category from the filter bar above.'
        ),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stroke),
            ),
            child: Icon(icon, size: 50, color: AppColors.cyan),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
