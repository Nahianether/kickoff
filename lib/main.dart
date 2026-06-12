import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the API key from .env. If the file is absent (e.g. a fresh clone with
  // no key yet), the app simply falls back to the bundled sample data.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present — continue with sample data.
  }

  runApp(
    const ProviderScope(
      child: KickOffApp(),
    ),
  );
}
