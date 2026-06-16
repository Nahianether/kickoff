import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/theme/theme_mode_provider.dart';
import 'src/features/competitions/competitions_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the API key from .env. If the file is absent (e.g. a fresh clone with
  // no key yet), the app simply falls back to the bundled sample data.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present — continue with sample data.
  }

  // Resolve persisted preferences before the first frame so the app opens
  // directly on the right league and brightness (no flicker through defaults).
  final defaultCompetition = await loadDefaultCompetition();
  final themeMode = await loadThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        bootstrapCompetitionProvider.overrideWithValue(defaultCompetition),
        bootstrapThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const KickOffApp(),
    ),
  );
}
