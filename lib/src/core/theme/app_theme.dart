import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual theme for KickOff — a premium black & teal look with a modern
/// typeface pairing (Outfit for headings, Inter for body).
class AppTheme {
  AppTheme._();

  static const Color _teal = Color(0xFF14B8A6); // vivid teal
  static const Color _tealBright = Color(0xFF2DD4BF);
  static const Color _ink = Color(0xFF05090B); // app background (near-black)
  static const Color _card = Color(0xFF0E1615); // elevated card surface
  static const Color _cardHigh = Color(0xFF16211F);

  /// Accent used for live matches across the app.
  static const Color live = Color(0xFFFF4D4F);

  /// Amber used for cached/default markers.
  static const Color amber = Color(0xFFE0A714);

  /// Gradient used for hero headers (top-left teal glow fading into surface).
  static const List<Color> heroGradient = [Color(0xFF123E39), _ink];

  /// The primary (and default) theme: black surfaces with teal accents.
  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: _teal,
      onPrimary: const Color(0xFF03110F),
      secondary: _tealBright,
      onSecondary: const Color(0xFF03110F),
      surface: _ink,
      onSurface: const Color(0xFFE9F5F2),
      surfaceContainerHighest: _cardHigh,
      surfaceContainerHigh: _card,
      onSurfaceVariant: const Color(0xFF92A9A4),
      outlineVariant: const Color(0xFF1E2E2C),
      outline: const Color(0xFF2A3D3A),
    );
    return _base(scheme, cardColor: _card);
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

  /// Modern type scale: Outfit for display/headline/title, Inter for body.
  static TextTheme _textTheme(ColorScheme scheme) {
    final body = GoogleFonts.interTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    );
    TextStyle outfit(TextStyle? s, FontWeight w) =>
        GoogleFonts.outfit(textStyle: s, fontWeight: w, letterSpacing: -0.2);
    return body
        .copyWith(
          displayLarge: outfit(body.displayLarge, FontWeight.w700),
          displayMedium: outfit(body.displayMedium, FontWeight.w700),
          displaySmall: outfit(body.displaySmall, FontWeight.w700),
          headlineMedium: outfit(body.headlineMedium, FontWeight.w700),
          headlineSmall: outfit(body.headlineSmall, FontWeight.w700),
          titleLarge: outfit(body.titleLarge, FontWeight.w700),
          titleMedium: outfit(body.titleMedium, FontWeight.w600),
        )
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
  }

  static ThemeData _base(ColorScheme scheme, {required Color cardColor}) {
    final textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
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
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
