import 'package:flutter/material.dart';

import '../providers/settings_provider.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color surfaceBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  /// A brighter border alternative used when the user has opted into
  /// high-contrast mode. Keeps widget outlines visible on AMOLED panels
  /// with heavy dimming.
  static const Color surfaceBorderHigh = Color(0x33FFFFFF);

  // Accent — "orange" is the historical default and is aliased into the
  // dynamic [accentFor] below. Keep `AppColors.orange` for places (asset
  // colors, explicit toasts) where a fixed accent is intentional.
  static const Color orange = Color(0xFFF97316);
  static const Color orangeDim = Color(0x33F97316);
  static const Color orangeGlow = Color(0x1AF97316);

  // Alternate accent palettes. Each palette has three variants: full
  // (buttons, active state), dim (20% track/background), glow (10% halo).
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDim = Color(0x333B82F6);
  static const Color blueGlow = Color(0x1A3B82F6);

  static const Color green = Color(0xFF22C55E);
  static const Color greenDim = Color(0x3322C55E);
  static const Color greenGlow = Color(0x1A22C55E);

  static const Color purple = Color(0xFFA855F7);
  static const Color purpleDim = Color(0x33A855F7);
  static const Color purpleGlow = Color(0x1AA855F7);

  /// Resolve the active accent color palette from user settings.
  static Color accentFor(AccentColor c) {
    switch (c) {
      case AccentColor.orange: return orange;
      case AccentColor.blue: return blue;
      case AccentColor.green: return green;
      case AccentColor.purple: return purple;
    }
  }

  /// 20%-alpha variant of the active accent (track / inactive background).
  static Color accentDimFor(AccentColor c) {
    switch (c) {
      case AccentColor.orange: return orangeDim;
      case AccentColor.blue: return blueDim;
      case AccentColor.green: return greenDim;
      case AccentColor.purple: return purpleDim;
    }
  }

  /// 10%-alpha variant of the active accent (glow / halo).
  static Color accentGlowFor(AccentColor c) {
    switch (c) {
      case AccentColor.orange: return orangeGlow;
      case AccentColor.blue: return blueGlow;
      case AccentColor.green: return greenGlow;
      case AccentColor.purple: return purpleGlow;
    }
  }

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color successDim = Color(0x2222C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDim = Color(0x22EF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Toasts / snackbars (muted variants for readability on dark backgrounds)
  static const Color toastSuccess = Color(0xFF166534);
  static const Color toastError = Color(0xFF7F1D1D);

  // Gauge
  static const Color gaugeTrack = Color(0xFF1F1F1F);
  static const Color gaugeActive = Color(0xFFF97316);
  static const Color gaugeDanger = Color(0xFFEF4444);
}

/// Canonical text style family. Every `TextStyle(fontFamily: 'Roboto', …)`
/// in the codebase is a legacy of when there was no theme-level default;
/// new code should prefer [kAppFontFamily] (or just omit the font and let
/// [AppTheme.dark] inject it). Exposed as a constant so that swapping the
/// font later is a one-line change.
const String kAppFontFamily = 'Roboto';

class AppTheme {
  /// Legacy entry point — preserved for callers that don't yet thread a
  /// user preference through. New code should prefer [AppTheme.build].
  static ThemeData get dark => build();

  /// Build the dark theme with the user's chosen [accent] and
  /// [highContrast] preferences. Kept pure (no Provider access) so it can
  /// be driven from either the top-level `MaterialApp.theme` or a preview
  /// widget.
  static ThemeData build({
    AccentColor accent = AccentColor.orange,
    bool highContrast = false,
  }) {
    final accentColor = AppColors.accentFor(accent);
    final accentDim = AppColors.accentDimFor(accent);
    final borderColor =
        highContrast ? AppColors.surfaceBorderHigh : AppColors.surfaceBorder;
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: kAppFontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: const TextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentDim;
          return AppColors.surfaceElevated;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
      ),
      useMaterial3: true,
      // Page-transition theme. When the user opts into reduce-motion the
      // app is switched to [NoTransitionsBuilder] at the [MaterialApp]
      // level — see `main.dart`. At rest we use the native platform
      // animations.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
