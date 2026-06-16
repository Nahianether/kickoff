import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

ThemeMode _decode(String? value) => switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // default: the signature black & teal look
    };

String _encode(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };

/// Reads the saved theme mode before the first frame (called in `main`) so the
/// app paints in the right brightness immediately — no flash from the default.
Future<ThemeMode> loadThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_kThemeModeKey));
  } catch (e) {
    debugPrint('loadThemeMode skipped: $e');
    return ThemeMode.dark;
  }
}

/// Seed for [themeModeProvider]; overridden in `main` with the persisted value.
final bootstrapThemeModeProvider =
    Provider<ThemeMode>((ref) => ThemeMode.dark);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(bootstrapThemeModeProvider);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, _encode(mode));
    } catch (e) {
      debugPrint('saveThemeMode skipped: $e');
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
