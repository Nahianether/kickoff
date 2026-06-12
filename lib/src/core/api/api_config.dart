import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for the football-data.org REST API.
///
/// The API key is read from a `.env` file (see `.env.example`) so it never has
/// to be committed to source control. Get a free key at
/// https://www.football-data.org/client/register
///
/// You can also override it at build time with:
///   flutter run --dart-define=FOOTBALL_API_KEY=your_key_here
///
/// If no key is found, the app falls back to bundled sample fixtures so it
/// still runs out of the box.
class ApiConfig {
  ApiConfig._();

  /// A --dart-define takes precedence (handy for CI), then the `.env` file.
  static const String _defineKey =
      String.fromEnvironment('FOOTBALL_API_KEY', defaultValue: '');

  static String get apiKey {
    if (_defineKey.isNotEmpty) return _defineKey;
    // Guard: dotenv throws if .env was never loaded (e.g. a clone with no key).
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('FOOTBALL_API_KEY') ?? '';
  }

  static bool get hasKey => apiKey.isNotEmpty;

  static const String baseUrl = 'https://api.football-data.org/v4';

  /// Competition code for the FIFA World Cup on football-data.org.
  static const String worldCupCode = 'WC';
}
