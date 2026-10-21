import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_state.dart';
import '../models/channel.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/focus_card.dart';

void openPlayer(BuildContext context, List<Channel> playlist, Channel channel) {
  final index = max(0, playlist.indexWhere((c) => c.url == channel.url));
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => PlayerScreen(playlist: playlist, initialIndex: index),
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 1.04, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ));
}

/// TV & Desktop Modern Live Player Screen
/// Features:
///   - Floating Glassmorphic Cyber Controls Deck
///   - Space / K: Play / Pause
///   - M: Mute / Unmute
///   - A: Aspect Ratio (16:9 Fit / Fullscreen Zoom / Stretch)
///   - ▲ / ▼: Next / Previous channel
///   - ◀ / ▶: Volume Adjust
///   - G or OK: Open / Close Channel Strip
///   - F: Favorite
///   - Auto-hides on inactivity with mouse movement reveal
class PlayerScreen extends StatefulWidget {
  final List<Channel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.playlist, required this.initialIndex});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: 16 * 1024 * 1024,
    ),
  );
  late final VideoController _video = VideoController(_player);
  final _rootFocus = FocusNode();
  final _subs = <StreamSubscription>[];

  late int _index = widget.initialIndex;
  bool _buffering = true;
  bool _gotFrame = false;
  String? _error;
  bool _showInfo = true;
  bool _showControls = true;
  bool _showStrip = false;
  int _autoSkips = 0;
  int _countdown = 0;

  bool _playing = true;
  double _volume = 100.0;
  double _prevVolume = 100.0;
  BoxFit _videoFit = BoxFit.contain;
  String? _toastMessage;
  Timer? _toastTimer;

  Timer? _hideTimer;
  Timer? _stallTimer;
  Timer? _countdownTimer;

  Channel get _channel => widget.playlist[_index];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _subs.addAll([
      _player.stream.buffering.listen((b) {
        if (mounted) setState(() => _buffering = b);
      }),
      _player.stream.error.listen((e) => _fail('This stream is offline or blocked in your region.')),
      _player.stream.width.listen((w) {
        if ((w ?? 0) > 0 && !_gotFrame) {
          _gotFrame = true;
          _autoSkips = 0;
          _stallTimer?.cancel();
        }
      }),
      _player.stream.playing.listen((p) {
        if (mounted) setState(() => _playing = p);
      }),
      _player.stream.volume.listen((v) {
        if (mounted) setState(() => _volume = v);
      }),
    ]);
    _open();
  }

  void _open() {
    _stallTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _error = null;
      _buffering = true;
      _gotFrame = false;
      _countdown = 0;
    });
    final ch = _channel;
    final headers = Map<String, String>.from(ch.headers);
    headers.putIfAbsent(
      'User-Agent',
      () => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );
    _player.open(Media(ch.url, httpHeaders: headers));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).markWatched(ch);
    });
    _pingControls();
    // Fast 6s timeout for minimal jitter & fast skipping
    _stallTimer = Timer(const Duration(seconds: 6), () {
      if (!_gotFrame) _fail('Stream connection timeout. Switching to next HD channel…');
    });
  }

  void _fail(String msg) {
    if (!mounted || _error != null || _gotFrame) return;
    _stallTimer?.cancel();
    _player.stop();
    setState(() {
      _error = msg;
      _buffering = false;
    });
    // Auto-skip dead channels quickly in 2 seconds
    if (_autoSkips < 8) {
      _countdown = 2;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _countdown--);
        if (_countdown <= 0) {
          t.cancel();
          _autoSkips++;
          _step(1);
        }
      });
    }
  }

  void _step(int delta) {
    final n = widget.playlist.length;
    _index = (_index + delta + n) % n;
    _open();
  }

  void _jumpTo(int i) {
    _autoSkips = 0;
    _index = i;
    _hideStrip();
    _open();
  }

  void _pingControls() {
    _hideTimer?.cancel();
    if (!_showControls || !_showInfo) {
      setState(() {
        _showControls = true;
        _showInfo = true;
      });
    }
    if (!_showStrip) {
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_showStrip) {
          setState(() {
            _showControls = false;
            _showInfo = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    if (_showStrip) {
      _hideStrip();
      return;
    }
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() {
        _showControls = false;
        _showInfo = false;
      });
    } else {
      _pingControls();
    }
  }

  void _togglePlayPause() {
    _pingControls();
    _player.playOrPause();
  }

  void _toggleMute() {
    _pingControls();
    if (_volume > 0) {
      _prevVolume = _volume;
      _player.setVolume(0.0);
      _flashToast('🔇 Muted');
    } else {
      final restored = _prevVolume > 0 ? _prevVolume : 100.0;
      _player.setVolume(restored);
      _flashToast('🔊 Volume: ${restored.round()}%');
    }
  }

  void _setVolume(double v) {
    _pingControls();
    _player.setVolume(v);
  }

  void _toggleAspectRatio() {
    _pingControls();
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover;
        _flashToast('Aspect: Zoom Fullscreen');
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill;
        _flashToast('Aspect: Stretch 16:9');
      } else {
        _videoFit = BoxFit.contain;
        _flashToast('Aspect: 16:9 Fit');
      }
    });
  }

  void _flashToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = msg);
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _openStrip() {
    _hideTimer?.cancel();
    setState(() {
      _showStrip = true;
      _showInfo = true;
      _showControls = false;
    });
    _armStripTimer();
  }

  void _armStripTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), _hideStrip);
  }

  void _hideStrip() {
    if (!mounted) return;
    setState(() {
      _showStrip = false;
    });
    _pingControls();
    _rootFocus.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;

    if (_showStrip) {
      _armStripTimer();
      if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.escape) {
        _hideStrip();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.channelUp) {
      _autoSkips = 0;
      _step(1);
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.channelDown) {
      _autoSkips = 0;
      _step(-1);
    } else if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.keyK) {
      _togglePlayPause();
    } else if (k == LogicalKeyboardKey.keyM) {
      _toggleMute();
    } else if (k == LogicalKeyboardKey.keyA) {
      _toggleAspectRatio();
    } else if (k == LogicalKeyboardKey.keyG ||
        k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter) {
      if (e is KeyDownEvent) _openStrip();
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _setVolume((_volume - 10).clamp(0.0, 100.0));
      _flashToast('🔊 Volume: ${_volume.round()}%');
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _setVolume((_volume + 10).clamp(0.0, 100.0));
      _flashToast('🔊 Volume: ${_volume.round()}%');
    } else if (k == LogicalKeyboardKey.keyF || k == LogicalKeyboardKey.contextMenu) {
      AppScope.read(context).toggleFavorite(_channel);
      _pingControls();
    } else if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _hideTimer?.cancel();
    _stallTimer?.cancel();
    _countdownTimer?.cancel();
    _toastTimer?.cancel();
    _player.dispose();
    _rootFocus.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 760;

    return PopScope(
      canPop: !_showStrip,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hideStrip();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _rootFocus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: MouseRegion(
            onHover: (_) => _pingControls(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() < 300) return;
                _autoSkips = 0;
                _step(v < 0 ? 1 : -1);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video output with selectable aspect ratio
                  Video(
                    controller: _video,
                    controls: NoVideoControls,
                    fit: _videoFit,
                    fill: Colors.black,
                  ),

                  // Buffering indicator
                  if (_buffering && _error == null)
                    Center(
                      child: _Glass(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cyan),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _gotFrame ? 'Buffering Stream…' : 'Connecting to Broadcast…',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'AI Zero-Jitter Buffer Active',
                                  style: TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_error != null) Center(child: _errorCard()),

                  // Flash Toast Indicator (Aspect Ratio, Volume, etc.)
                  if (_toastMessage != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.6)),
                          boxShadow: [
                            BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35), blurRadius: 24),
                          ],
                        ),
                        child: Text(
                          _toastMessage!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),

                  // Top info bar (Slide in/out)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    top: _showInfo ? 0 : -200,
                    left: 0,
                    right: 0,
                    child: _TopBar(
                      channel: _channel,
                      number: _index + 1,
                      total: widget.playlist.length,
                      favorite: s.isFavorite(_channel),
                      narrow: narrow,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ),

                  // Modern Floating Player Controls Deck (Bottom)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    bottom: (_showControls && !_showStrip) ? (narrow ? 16 : 28) : -220,
                    left: narrow ? 14 : 48,
                    right: narrow ? 14 : 48,
                    child: IgnorePointer(
                      ignoring: !_showControls || _showStrip,
                      child: _ModernPlayerControlsDeck(
                        channel: _channel,
                        number: _index + 1,
                        total: widget.playlist.length,
                        playing: _playing,
                        volume: _volume,
                        videoFit: _videoFit,
                        favorite: s.isFavorite(_channel),
                        narrow: narrow,
                        onPlayPause: _togglePlayPause,
                        onPrevChannel: () {
                          _autoSkips = 0;
                          _step(-1);
                        },
                        onNextChannel: () {
                          _autoSkips = 0;
                          _step(1);
                        },
                        onToggleMute: _toggleMute,
                        onVolumeChanged: _setVolume,
                        onToggleAspectRatio: _toggleAspectRatio,
                        onToggleFavorite: () => s.toggleFavorite(_channel),
                        onToggleGuide: _openStrip,
                        onUserAction: _pingControls,
                      ),
                    ),
                  ),

                  // Channel strip (Bottom)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    bottom: _showStrip ? 0 : -340,
                    left: 0,
                    right: 0,
                    child: _showStrip
                        ? _ChannelStrip(
                            playlist: widget.playlist,
                            current: _index,
                            isFavorite: s.isFavorite,
                            onPick: _jumpTo,
                            onFavorite: () => s.toggleFavorite(_channel),
                            currentFavorite: s.isFavorite(_channel),
                            narrow: narrow,
                            onClose: _hideStrip,
                          )
                        : const SizedBox(height: 260),
                  ),

                  // Floating hint when controls are auto-hidden
                  if (!_showInfo && !_showStrip && _error == null && !narrow)
                    Positioned(
                      bottom: 24,
                      right: 36,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          '▲▼ Channel Switch   ·   Space Play/Pause   ·   A Aspect Ratio   ·   OK Strip',
                          style: TextStyle(color: Colors.white60, fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w600),
                        ),
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

  Widget _errorCard() {
    return _Glass(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.live.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.live.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.portable_wifi_off_rounded, color: AppColors.live, size: 32),
          ),
          const SizedBox(height: 18),
          const Text('Broadcast Stream Offline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_error!, style: const TextStyle(color: AppColors.textDim)),
          if (_countdown > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent2.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.accent2.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Auto-skipping to next channel in $_countdown…',
                style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              PillButton(
                icon: Icons.refresh_rounded,
                label: 'Retry Stream',
                onTap: () {
                  _autoSkips = 0;
                  _open();
                },
              ),
              PillButton(
                icon: Icons.skip_next_rounded,
                label: 'Next Channel',
                primary: true,
                autofocus: true,
                onTap: () {
                  _autoSkips = 0;
                  _step(1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating glassmorphic controls deck for modern TV & web video playback.
class _ModernPlayerControlsDeck extends StatelessWidget {
  final Channel channel;
  final int number;
  final int total;
  final bool playing;
  final double volume;
  final BoxFit videoFit;
  final bool favorite;
  final bool narrow;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevChannel;
  final VoidCallback onNextChannel;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleAspectRatio;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleGuide;
  final VoidCallback onUserAction;

  const _ModernPlayerControlsDeck({
    required this.channel,
    required this.number,
    required this.total,
    required this.playing,
    required this.volume,
    required this.videoFit,
    required this.favorite,
    required this.narrow,
    required this.onPlayPause,
    required this.onPrevChannel,
    required this.onNextChannel,
    required this.onToggleMute,
    required this.onVolumeChanged,
    required this.onToggleAspectRatio,
    required this.onToggleFavorite,
    required this.onToggleGuide,
    required this.onUserAction,
  });

  String get _aspectLabel {
    if (videoFit == BoxFit.contain) return '16:9 Fit';
    if (videoFit == BoxFit.cover) return 'Zoom Fill';
    return 'Stretch';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 16 : 24,
                vertical: narrow ? 14 : 16,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xDD0B132B),
                    Color(0xEE020617),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.22),
                    blurRadius: 36,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Telemetry / Stream Info Bar
                  Row(
                    children: [
                      const _MiniLiveBeacon(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${channel.displayQuality} · 60FPS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyan,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!narrow) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Colors.amberAccent),
                              const SizedBox(width: 3),
                              Text(
                                'ZERO-JITTER STREAM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        'CH $number / $total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),

                  // Bottom Interactive Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Playback Core: Prev, Play/Pause Cyber Button, Next
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlassIconButton(
                            icon: Icons.skip_previous_rounded,
                            tooltip: 'Previous Channel (▲)',
                            size: narrow ? 42 : 46,
                            iconSize: 24,
                            onTap: () {
                              onUserAction();
                              onPrevChannel();
                            },
                          ),
                          const SizedBox(width: 12),
                          _CyberPlayButton(
                            playing: playing,
                            size: narrow ? 52 : 58,
                            onTap: () {
                              onUserAction();
                              onPlayPause();
                            },
                          ),
                          const SizedBox(width: 12),
                          _GlassIconButton(
                            icon: Icons.skip_next_rounded,
                            tooltip: 'Next Channel (▼)',
                            size: narrow ? 42 : 46,
                            iconSize: 24,
                            onTap: () {
                              onUserAction();
                              onNextChannel();
                            },
                          ),
                        ],
                      ),

                      if (!narrow) ...[
                        const SizedBox(width: 16),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(width: 16),
                      ],

                      // Volume & Mute Control
                      if (!narrow) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GlassIconButton(
                              icon: volume <= 0
                                  ? Icons.volume_off_rounded
                                  : (volume < 50 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                              tooltip: volume <= 0 ? 'Unmute (M)' : 'Mute (M)',
                              color: volume <= 0 ? Colors.redAccent : Colors.white,
                              size: 38,
                              iconSize: 20,
                              onTap: () {
                                onUserAction();
                                onToggleMute();
                              },
                            ),
                            SizedBox(
                              width: 80,
                              child: SliderTheme(
                                data: const SliderThemeData(
                                  trackHeight: 3.5,
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                                  activeTrackColor: AppColors.cyan,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: volume.clamp(0.0, 100.0),
                                  min: 0,
                                  max: 100,
                                  onChanged: (v) {
                                    onUserAction();
                                    onVolumeChanged(v);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              '${volume.round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(width: 16),
                      ],

                      // Action Buttons: Aspect Ratio, Favorite, Channel Guide
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Aspect Ratio Pill
                          _GlassPillButton(
                            icon: Icons.aspect_ratio_rounded,
                            label: _aspectLabel,
                            onTap: () {
                              onUserAction();
                              onToggleAspectRatio();
                            },
                          ),
                          const SizedBox(width: 8),

                          // Favorite Button
                          _GlassIconButton(
                            icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: favorite ? AppColors.accent2 : Colors.white70,
                            tooltip: 'Favorite Channel (F)',
                            size: narrow ? 38 : 42,
                            iconSize: 20,
                            onTap: () {
                              onUserAction();
                              onToggleFavorite();
                            },
                          ),
                          const SizedBox(width: 8),

                          // Guide Toggle Button
                          _GlassPillButton(
                            icon: Icons.grid_view_rounded,
                            label: 'Guide',
                            primary: true,
                            onTap: () {
                              onUserAction();
                              onToggleGuide();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberPlayButton extends StatelessWidget {
  final bool playing;
  final double size;
  final VoidCallback onTap;

  const _CyberPlayButton({
    required this.playing,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      autofocus: false,
      onSelect: onTap,
      radius: BorderRadius.circular(size / 2),
      builder: (context, focused) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.cyan, Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: focused ? 0.8 : 0.45),
                blurRadius: focused ? 24 : 16,
                spreadRadius: focused ? 3 : 0,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: focused ? 1.0 : 0.4),
              width: focused ? 2.5 : 1.2,
            ),
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: size * 0.58,
          ),
        );
      },
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color color;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 42,
    this.iconSize = 22,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FocusCard(
        onSelect: onTap,
        radius: BorderRadius.circular(size / 2),
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: focused
                  ? AppColors.cyan.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: focused ? AppColors.cyan : Colors.white.withValues(alpha: 0.18),
                width: focused ? 2 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.5),
                        blurRadius: 14,
                      )
                    ]
                  : null,
            ),
            child: Icon(icon, size: iconSize, color: focused ? Colors.white : color),
          );
        },
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _GlassPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      onSelect: onTap,
      radius: BorderRadius.circular(100),
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0080FF)],
                  )
                : null,
            color: primary
                ? null
                : (focused ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08)),
            border: Border.all(
              color: focused
                  ? Colors.white
                  : (primary ? AppColors.cyan : Colors.white.withValues(alpha: 0.18)),
              width: focused ? 1.8 : 1,
            ),
            boxShadow: focused || primary
                ? [
                    BoxShadow(
                      color: (primary ? AppColors.cyan : Colors.white).withValues(alpha: 0.35),
                      blurRadius: 14,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: primary ? Colors.black : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary ? Colors.black : Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniLiveBeacon extends StatefulWidget {
  const _MiniLiveBeacon();

  @override
  State<_MiniLiveBeacon> createState() => _MiniLiveBeaconState();
}

class _MiniLiveBeaconState extends State<_MiniLiveBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.live.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.live.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.live,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.live.withValues(alpha: 0.8),
                    blurRadius: 4 + 4 * _ctrl.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.live,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Glass({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: child,
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  final Channel channel;
  final int number;
  final int total;
  final bool favorite;
  final bool narrow;
  final VoidCallback onBack;

  const _TopBar({
    required this.channel,
    required this.number,
    required this.total,
    required this.favorite,
    required this.narrow,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 48, narrow ? 20 : 36, narrow ? 16 : 48, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.92), Colors.transparent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back (Esc)',
            size: narrow ? 44 : 50,
            iconSize: 22,
            onTap: onBack,
          ),
          const SizedBox(width: 14),

          // Channel Logo Badge
          Container(
            width: narrow ? 68 : 88,
            height: narrow ? 68 : 88,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ChannelLogo(channel: channel, size: narrow ? 60 : 78),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'CH ${number.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const LiveBadge(),
                    Tag(channel.countryFlag, highlight: true),
                    Tag(channel.displayQuality),
                    if (favorite)
                      const Icon(Icons.favorite_rounded, size: 18, color: AppColors.accent2),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: narrow ? 22 : 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${channel.group}${channel.country.isNotEmpty ? '  ·  ${channel.country}' : ''}  ·  AI Low-Latency Stream',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClockText(style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(
                  'Channel $number of $total',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelStrip extends StatelessWidget {
  final List<Channel> playlist;
  final int current;
  final bool Function(Channel) isFavorite;
  final ValueChanged<int> onPick;
  final VoidCallback onFavorite;
  final bool currentFavorite;
  final bool narrow;
  final VoidCallback onClose;

  const _ChannelStrip({
    required this.playlist,
    required this.current,
    required this.isFavorite,
    required this.onPick,
    required this.onFavorite,
    required this.currentFavorite,
    required this.narrow,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final itemW = narrow ? 130.0 : 176.0;
    const gap = 16.0;
    final hPad = narrow ? 20.0 : 48.0;
    final screenW = MediaQuery.sizeOf(context).width;
    final offset = max(0.0, current * (itemW + gap) - screenW / 2 + itemW / 2 + hPad);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(top: 24, bottom: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.95),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
            border: const Border(top: BorderSide(color: AppColors.stroke)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  children: [
                    const Text('Live Channel Strip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${playlist.length} TOTAL',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyan),
                      ),
                    ),
                    const Spacer(),
                    FocusTraversalGroup(
                      child: PillButton(
                        icon: currentFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        label: currentFavorite ? 'Favorited' : 'Favorite',
                        onTap: onFavorite,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GlassIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close Strip (Down / Esc)',
                      size: 38,
                      iconSize: 18,
                      onTap: onClose,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: narrow ? 130 : 156,
                child: FocusTraversalGroup(
                  child: ListView.builder(
                    controller: ScrollController(initialScrollOffset: offset),
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    itemExtent: itemW + gap,
                    itemCount: playlist.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: gap),
                      child: _MiniCard(
                        channel: playlist[i],
                        playing: i == current,
                        favorite: isFavorite(playlist[i]),
                        autofocus: i == current,
                        onTap: () => onPick(i),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Channel channel;
  final bool playing;
  final bool favorite;
  final bool autofocus;
  final VoidCallback onTap;

  const _MiniCard({
    required this.channel,
    required this.playing,
    required this.favorite,
    required this.autofocus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      autofocus: autofocus,
      onSelect: onTap,
      radius: BorderRadius.circular(18),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: focused
              ? Colors.white.withValues(alpha: 0.18)
              : playing
                  ? AppColors.cyan.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: focused
                ? Colors.white
                : (playing ? AppColors.cyan : Colors.white12),
            width: focused || playing ? 2 : 1,
          ),
          boxShadow: playing
              ? [
                  BoxShadow(color: AppColors.cyan.withValues(alpha: 0.3), blurRadius: 14),
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(child: ChannelLogo(channel: channel, size: 52)),
                  if (playing)
                    const Positioned(
                      top: 0,
                      left: 0,
                      child: _EqualizerIcon(),
                    ),
                  if (favorite)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.favorite_rounded, size: 14, color: AppColors.accent2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: playing ? FontWeight.w800 : FontWeight.w600,
                color: playing ? AppColors.cyan : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EqualizerIcon extends StatefulWidget {
  const _EqualizerIcon();
  @override
  State<_EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<_EqualizerIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 2.5, height: 6 + 6 * _c.value, color: AppColors.cyan),
              const SizedBox(width: 2),
              Container(width: 2.5, height: 12 - 6 * _c.value, color: AppColors.cyan),
              const SizedBox(width: 2),
              Container(width: 2.5, height: 8 + 4 * _c.value, color: AppColors.cyan),
            ],
          ),
        );
      },
    );
  }
}
