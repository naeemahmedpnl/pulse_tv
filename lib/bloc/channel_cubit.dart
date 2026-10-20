import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';
import '../services/logo_cache_service.dart';
import '../services/playlist_service.dart';
import 'channel_state.dart';

/// High-performance Cubit managing IPTV channel playlists, favorites, and history.
class ChannelCubit extends Cubit<ChannelState> {
  final PlaylistService _service;
  SharedPreferences? _prefs;

  ChannelCubit({PlaylistService? service})
      : _service = service ?? PlaylistService(),
        super(ChannelState.initial());

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final favorites = (_prefs!.getStringList('favorites') ?? []).toSet();
    var recent = _prefs!.getStringList('recent') ?? [];
    final saved = _prefs!.getStringList('sources');

    List<String> sources;
    if (saved == null || saved.any((s) => s.contains('de.m3u') || s.contains('categories/news.m3u'))) {
      sources = List.of(PlaylistService.defaultSources);
      await _prefs!.setStringList('sources', sources);
    } else {
      sources = saved;
    }

    emit(state.copyWith(
      favorites: favorites,
      recent: recent,
      sources: sources,
    ));

    // Instant 0ms recall: Load cached channels from local disk/storage first
    final cached = await _service.loadCache(_prefs!);
    if (cached.isNotEmpty) {
      _applyChannels(cached, loading: false);
      LogoCacheService.instance.prewarm(cached);
    }

    // Background live refresh
    await refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(
      refreshing: true,
      loading: state.channels.isEmpty,
      clearError: true,
    ));

    try {
      final list = await _service.fetchAll(state.sources);
      if (list.isEmpty) {
        throw Exception('No channels found. Check your playlist URLs in Settings.');
      }
      _applyChannels(list, loading: false, refreshing: false);
      if (_prefs != null) await _service.saveCache(_prefs!, list);
      LogoCacheService.instance.prewarm(list);
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        error: state.channels.isEmpty ? e.toString().replaceFirst('Exception: ', '') : null,
      ));
    }
  }

  void _applyChannels(
    List<Channel> list, {
    bool? loading,
    bool? refreshing,
  }) {
    final counts = <String, int>{};
    for (final c in list) {
      counts[c.group] = (counts[c.group] ?? 0) + 1;
    }
    final groups = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    emit(state.copyWith(
      channels: list,
      groups: groups,
      loading: loading,
      refreshing: refreshing,
      clearError: true,
    ));
  }

  void toggleFavorite(Channel c) {
    final updated = Set<String>.from(state.favorites);
    if (!updated.remove(c.url)) {
      updated.add(c.url);
    }
    _prefs?.setStringList('favorites', updated.toList());
    emit(state.copyWith(favorites: updated));
  }

  void markWatched(Channel c) {
    final updated = List<String>.from(state.recent);
    updated
      ..remove(c.url)
      ..insert(0, c.url);
    final trimmed = updated.length > 20 ? updated.sublist(0, 20) : updated;
    _prefs?.setStringList('recent', trimmed);
    emit(state.copyWith(recent: trimmed));
  }

  Future<void> setSources(List<String> list) async {
    await _prefs?.setStringList('sources', list);
    emit(state.copyWith(sources: list, channels: const []));
    await refresh();
  }
}
