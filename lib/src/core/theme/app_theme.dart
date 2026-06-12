import 'package:flutter/material.dart';

/// Visual theme for KickOff — a black & teal look.
class AppTheme {
  AppTheme._();

  static const Color _teal = Color(0xFF14B8A6); // vivid teal
  static const Color _tealBright = Color(0xFF2DD4BF);
  static const Color _black = Color(0xFF000000);
  static const Color _nearBlack = Color(0xFF0B1110); // teal-tinted black

  /// The primary (and default) theme: black surfaces with teal accents.
  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: _teal,
      onPrimary: Colors.black,
      secondary: _tealBright,
      onSecondary: Colors.black,
      surface: _black,
      onSurface: const Color(0xFFE6F4F1),
      surfaceContainerHighest: const Color(0xFF16201E),
      onSurfaceVariant: const Color(0xFF9CB3AE),
      outlineVariant: const Color(0xFF223230),
    );
    return _base(scheme, cardColor: _nearBlack);
  }

  /// A light variant (still teal-led) for users on a light system theme.
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _teal,
      primary: const Color(0xFF0F766E),
      secondary: _teal,
    );
    return _base(scheme, cardColor: Colors.white);
  }

  static ThemeData _base(ColorScheme scheme, {required Color cardColor}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 62,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
