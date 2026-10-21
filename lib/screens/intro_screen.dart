import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/focus_card.dart';
import 'home_screen.dart';

/// Modern aesthetic intro & onboarding screen for Pulse TV.
class IntroScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const IntroScreen({super.key, this.onComplete});

  static const String prefKey = 'pulse_tv_seen_intro_v2';

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _dontShowAgain = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _finishIntro() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(IntroScreen.prefKey, true);
    }
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 800;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _finishIntro,
        const SingleActivator(LogicalKeyboardKey.space): _finishIntro,
        const SingleActivator(LogicalKeyboardKey.escape): _finishIntro,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF04060C),
          body: Stack(
            children: [
              // Ambient animated cyber gradients
              Positioned(
                top: -120,
                left: -100,
                width: 520,
                height: 520,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -160,
                right: -120,
                width: 600,
                height: 600,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF007A).withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.25,
                right: size.width * 0.15,
                width: 400,
                height: 400,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Glass Grid Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _CyberGridPainter(),
                ),
              ),

              // Main Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 24 : 48,
                      vertical: 32,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF00E5FF)),
                                    SizedBox(width: 8),
                                    Text(
                                      'NEXT-GEN TELEVISION SUITE • MACOS & NATIVE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Big Brand Logo
                              const PulseTvBrandLogo(size: 64, withText: true),
                              const SizedBox(height: 20),

                              // Hero Title
                              ShaderMask(
                                shaderCallback: (r) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFF00E5FF), Color(0xFFD4DEFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(r),
                                child: Text(
                                  'Experience Pure Live Broadcast',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 32 : 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 680),
                                child: const Text(
                                  'High-definition streaming engine engineered for Pakistan & India premier channels with zero-jitter playback, instant logo recall, and native hardware acceleration.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 38),

                              // 4 Feature Pillars Grid
                              Wrap(
                                spacing: 18,
                                runSpacing: 18,
                                alignment: WrapAlignment.center,
                                children: [
                                  _FeatureCard(
                                    icon: Icons.flag_rounded,
                                    accentColor: const Color(0xFF00FF7F),
                                    title: '🇵🇰 Pakistan Premier',
                                    description: '70+ Top Channels: ARY, Geo, 24 News, Dunya, Ten Sports, PTV & Hum in pure 1080p.',
                                    width: isCompact ? size.width : 240,
                                  ),
                                  _FeatureCard(
                                    icon: Icons.movie_filter_rounded,
                                    accentColor: const Color(0xFFFF9933),
                                    title: '🇮🇳 India Premier',
                                    description: '400+ Channels: Star Sports, Sony, Zee, Aaj Tak, Colors & 9X Music suite.',
                                    width: isCompact ? size.width : 240,
                                  ),
                                  _FeatureCard(
                                    icon: Icons.bolt_rounded,
                                    accentColor: const Color(0xFF00E5FF),
                                    title: '⚡ Zero-Jitter Engine',
                                    description: 'Low-latency prefetch buffer with intelligent memory cache & auto stream recovery.',
                                    width: isCompact ? size.width : 240,
                                  ),
                                  _FeatureCard(
                                    icon: Icons.laptop_mac_rounded,
                                    accentColor: const Color(0xFFFF007A),
                                    title: '🍎 Native macOS App',
                                    description: 'Built for Apple Silicon & Intel with keyboard navigation, hotkeys & picture-in-picture.',
                                    width: isCompact ? size.width : 240,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 44),

                              // Launch Button Action
                              FocusCard(
                                focusScale: 1.05,
                                radius: BorderRadius.circular(20),
                                onSelect: _finishIntro,
                                builder: (context, focused) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00E5FF),
                                        Color(0xFF8B5CF6),
                                        Color(0xFFFF007A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: focused ? 0.6 : 0.35),
                                        blurRadius: focused ? 32 : 20,
                                        spreadRadius: focused ? 1 : -2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                                      SizedBox(width: 10),
                                      Text(
                                        'START WATCHING NOW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Bottom controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _dontShowAgain,
                                    activeColor: const Color(0xFF00E5FF),
                                    checkColor: Colors.black,
                                    side: const BorderSide(color: Colors.white38),
                                    onChanged: (val) {
                                      setState(() => _dontShowAgain = val ?? true);
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _dontShowAgain = !_dontShowAgain);
                                    },
                                    child: const Text(
                                      "Don't show this intro on launch",
                                      style: TextStyle(color: AppColors.textDim, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  TextButton(
                                    onPressed: _finishIntro,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.textMuted,
                                    ),
                                    child: const Text('Skip (Enter ↵)'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final double width;

  const _FeatureCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1322).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textDim,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.018)
      ..strokeWidth = 1.0;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
