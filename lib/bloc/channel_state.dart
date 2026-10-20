import '../models/channel.dart';
import '../services/playlist_service.dart';

/// Immutable state for ChannelCubit.
class ChannelState {
  final List<Channel> channels;
  final List<String> groups;
  final Set<String> favorites;
  final List<String> recent;
  final List<String> sources;
  final bool loading;
  final bool refreshing;
  final String? error;

  const ChannelState({
    this.channels = const [],
    this.groups = const [],
    this.favorites = const {},
    this.recent = const [],
    this.sources = const [],
    this.loading = true,
    this.refreshing = false,
    this.error,
  });

  factory ChannelState.initial() => ChannelState(
        sources: List.of(PlaylistService.defaultSources),
        loading: true,
      );

  ChannelState copyWith({
    List<Channel>? channels,
    List<String>? groups,
    Set<String>? favorites,
    List<String>? recent,
    List<String>? sources,
    bool? loading,
    bool? refreshing,
    String? error,
    bool clearError = false,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      groups: groups ?? this.groups,
      favorites: favorites ?? this.favorites,
      recent: recent ?? this.recent,
      sources: sources ?? this.sources,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Channel> byGroup(String g) =>
      channels.where((c) => c.group == g).toList();

  List<Channel> get favoriteChannels =>
      channels.where((c) => favorites.contains(c.url)).toList();

  List<Channel> get recentChannels {
    final map = {for (final c in channels) c.url: c};
    return recent.map((u) => map[u]).whereType<Channel>().toList();
  }

  Channel? get featured {
    final r = recentChannels;
    if (r.isNotEmpty) return r.first;
    return channels.isNotEmpty ? channels.first : null;
  }

  List<Channel> search(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return channels;
    return channels
        .where((c) =>
            c.name.toLowerCase().contains(s) ||
            c.group.toLowerCase().contains(s) ||
            c.country.toLowerCase() == s)
        .toList();
  }

  bool isFavorite(Channel c) => favorites.contains(c.url);
}
