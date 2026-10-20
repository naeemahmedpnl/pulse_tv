import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

import '../models/channel.dart';

/// High-performance logo caching service.
/// Provides persistent caching, image pre-warming, and zero-latency logo rendering.
class LogoCacheService {
  static final LogoCacheService instance = LogoCacheService._();
  LogoCacheService._();

  final Set<String> _prewarmed = {};
  bool _isPrewarming = false;

  /// Warms up logos in batches to fill memory cache and disk cache without choking network.
  Future<void> prewarm(List<Channel> channels) async {
    if (_isPrewarming) return;
    _isPrewarming = true;

    try {
      final toWarm = channels
          .where((c) => c.logo.isNotEmpty && !_prewarmed.contains(c.logo))
          .toList();

      const batchSize = 10;
      for (var i = 0; i < toWarm.length; i += batchSize) {
        final end = (i + batchSize < toWarm.length) ? i + batchSize : toWarm.length;
        final batch = toWarm.sublist(i, end);

        await Future.wait(batch.map((c) => _precacheSingle(c.logo)));
        // Yield to event loop to keep UI 60/120fps smooth
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } catch (_) {
      // Background pre-warming should never crash app
    } finally {
      _isPrewarming = false;
    }
  }

  Future<void> _precacheSingle(String url) async {
    if (_prewarmed.contains(url)) return;
    _prewarmed.add(url);

    try {
      final provider = CachedNetworkImageProvider(
        url,
        maxWidth: 300,
        maxHeight: 300,
      );

      final stream = provider.resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, sync) {
          if (!completer.isCompleted) completer.complete();
          stream.removeListener(listener);
        },
        onError: (err, st) {
          if (!completer.isCompleted) completer.complete();
          stream.removeListener(listener);
        },
      );

      stream.addListener(listener);
      await completer.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    } catch (_) {}
  }

  /// Check if a logo is already in memory cache
  bool isCached(String url) => _prewarmed.contains(url);
}
