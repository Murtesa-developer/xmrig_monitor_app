import 'package:flutter/material.dart';

/// Design tokens: every colour the UI uses beyond Material's ColorScheme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.muted,
    required this.good,
    required this.warn,
    required this.bad,
    required this.terminal,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color bg, card, cardAlt, border, muted, good, warn, bad, terminal, heroStart, heroEnd;

  static const dark = AppPalette(
    bg: Color(0xFF0D0F12),
    card: Color(0xFF15191E),
    cardAlt: Color(0xFF1B2027),
    border: Color(0xFF262C34),
    muted: Color(0xFF8B95A3),
    good: Color(0xFF34D399),
    warn: Color(0xFFFBBF24),
    bad: Color(0xFFF87171),
    terminal: Color(0xFF0A0C0F),
    heroStart: Color(0xFFFF8A3D),
    heroEnd: Color(0xFFE5484D),
  );

  static const light = AppPalette(
    bg: Color(0xFFF4F5F7),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF0F2F5),
    border: Color(0xFFE2E5EA),
    muted: Color(0xFF667085),
    good: Color(0xFF12A36B),
    warn: Color(0xFFD97706),
    bad: Color(0xFFDC2626),
    terminal: Color(0xFF101319),
    heroStart: Color(0xFFFF8A3D),
    heroEnd: Color(0xFFE5484D),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? card,
    Color? cardAlt,
    Color? border,
    Color? muted,
    Color? good,
    Color? warn,
    Color? bad,
    Color? terminal,
    Color? heroStart,
    Color? heroEnd,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        card: card ?? this.card,
        cardAlt: cardAlt ?? this.cardAlt,
        border: border ?? this.border,
        muted: muted ?? this.muted,
        good: good ?? this.good,
        warn: warn ?? this.warn,
        bad: bad ?? this.bad,
        terminal: terminal ?? this.terminal,
        heroStart: heroStart ?? this.heroStart,
        heroEnd: heroEnd ?? this.heroEnd,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg),
      card: l(card, other.card),
      cardAlt: l(cardAlt, other.cardAlt),
      border: l(border, other.border),
      muted: l(muted, other.muted),
      good: l(good, other.good),
      warn: l(warn, other.warn),
      bad: l(bad, other.bad),
      terminal: l(terminal, other.terminal),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
    );
  }
}

extension ThemeX on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
  TextTheme get tt => Theme.of(this).textTheme;
  ColorScheme get cs => Theme.of(this).colorScheme;
}
