import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';

const kAccent = Color(0xFFFF8A3D);

/// Numbers that change often use equal-width digits so they don't jitter.
TextStyle numStyle(TextStyle? base) =>
    (base ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);
  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static OutlineInputBorder _outline(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData _build(Brightness b, AppPalette p) {
    final scheme = ColorScheme.fromSeed(seedColor: kAccent, brightness: b).copyWith(
      primary: kAccent,
      onPrimary: const Color(0xFF1A1208),
      surface: p.card,
      error: p.bad,
    );
    final base = ThemeData(brightness: b, colorScheme: scheme, useMaterial3: true);
    final tt = base.textTheme;
    final text = tt
        .copyWith(
          headlineMedium: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelMedium: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      textTheme: text,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardAlt,
        border: _outline(p.border),
        enabledBorder: _outline(p.border),
        focusedBorder: _outline(kAccent, 1.6),
        errorBorder: _outline(p.bad),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.7)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: kAccent.withValues(alpha: 0.18),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.card,
        indicatorColor: kAccent.withValues(alpha: 0.18),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: kAccent),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: p.muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      sliderTheme: const SliderThemeData(trackHeight: 4),
    );
  }
}
