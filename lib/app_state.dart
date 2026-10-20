import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/channel_cubit.dart';
import 'bloc/channel_state.dart';
import 'models/channel.dart';

/// AppState bridging to reactive BLoC/Cubit architecture.
class AppState extends ChangeNotifier {
  final ChannelCubit cubit;
  late final StreamSubscription<ChannelState> _sub;

  AppState({ChannelCubit? channelCubit})
      : cubit = channelCubit ?? ChannelCubit() {
    _sub = cubit.stream.listen((_) {
      notifyListeners();
    });
  }

  Future<void> init() => cubit.init();
  Future<void> refresh() => cubit.refresh();

  List<Channel> get channels => cubit.state.channels;
  List<String> get groups => cubit.state.groups;
  Set<String> get favorites => cubit.state.favorites;
  List<String> get recent => cubit.state.recent;
  List<String> get sources => cubit.state.sources;
  bool get loading => cubit.state.loading;
  bool get refreshing => cubit.state.refreshing;
  String? get error => cubit.state.error;

  List<Channel> byGroup(String g) => cubit.state.byGroup(g);
  List<Channel> get favoriteChannels => cubit.state.favoriteChannels;
  List<Channel> get recentChannels => cubit.state.recentChannels;
  Channel? get featured => cubit.state.featured;
  List<Channel> search(String q) => cubit.state.search(q);
  bool isFavorite(Channel c) => cubit.state.isFavorite(c);
  void toggleFavorite(Channel c) => cubit.toggleFavorite(c);
  void markWatched(Channel c) => cubit.markWatched(c);
  Future<void> setSources(List<String> list) => cubit.setSources(list);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Lightweight dependency injection & convenience accessors.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// BuildContext extension for direct BLoC / Cubit access across the app.
extension ChannelContextX on BuildContext {
  ChannelCubit get channelCubit => read<ChannelCubit>();
  ChannelState get channelState => watch<ChannelCubit>().state;
}
