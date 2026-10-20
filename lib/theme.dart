import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pulse TV design tokens — an agentic, cinematic dark palette with neon cyber accents.
class AppColors {
  static const bg = Color(0xFF06070B);
  static const surface = Color(0xFF0F111A);
  static const surfaceHi = Color(0xFF171A26);
  static const surfaceCard = Color(0xFF131622);
  static const stroke = Color(0x1FFFFFFF);
  static const strokeGlow = Color(0x407C5CFF);
  
  static const text = Color(0xFFF6F8FC);
  static const textDim = Color(0xFF8B92A4);
  static const textMuted = Color(0xFF555B6E);
  
  // Neon Accents
  static const accent = Color(0xFF7C5CFF);      // Electric Violet
  static const accent2 = Color(0xFFFF3388);     // Hyper Magenta
  static const cyan = Color(0xFF00F2FE);        // Cyber Cyan
  static const emerald = Color(0xFF00F5A0);     // Live Emerald
  static const amber = Color(0xFFFFB800);       // Warm Gold
  static const live = Color(0xFFFF2E4D);        // Radiant Live Red
}

const accentGradient = LinearGradient(
  colors: [AppColors.accent, AppColors.accent2],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const cyberGradient = LinearGradient(
  colors: [AppColors.accent, AppColors.cyan],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const agenticGradient = LinearGradient(
  colors: [Color(0xFF8A5CFF), Color(0xFFFF3388), Color(0xFF00E5FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const emeraldGradient = LinearGradient(
  colors: [AppColors.emerald, Color(0xFF00D1FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      tertiary: AppColors.cyan,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    // We draw our own focus states — kill Material's grey overlays.
    focusColor: Colors.transparent,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHi.withOpacity(0.85),
      hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
    ),
  );
}
