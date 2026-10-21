import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'bloc/channel_cubit.dart';
import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // High capacity image cache for instant channel logo recall
  PaintingBinding.instance.imageCache.maximumSize = 3000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 * 1024 * 1024; // 250MB

  final prefs = await SharedPreferences.getInstance();
  final seenIntro = prefs.getBool(IntroScreen.prefKey) ?? false;

  final channelCubit = ChannelCubit();
  channelCubit.init();
  final state = AppState(channelCubit: channelCubit);

  runApp(PulseApp(channelCubit: channelCubit, state: state, seenIntro: seenIntro));
}

class PulseApp extends StatelessWidget {
  final ChannelCubit channelCubit;
  final AppState state;
  final bool seenIntro;
  const PulseApp({super.key, required this.channelCubit, required this.state, this.seenIntro = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChannelCubit>.value(
      value: channelCubit,
      child: AppScope(
        notifier: state,
        child: MaterialApp(
          title: 'Pulse TV',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: seenIntro ? const HomeScreen() : const IntroScreen(),
        ),
      ),
    );
  }
}

