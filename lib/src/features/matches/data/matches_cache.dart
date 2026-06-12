import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A previously stored API response plus when it was fetched.
class RawCache {
  final String json;
  final DateTime fetchedAt;
  const RawCache(this.json, this.fetchedAt);
}

/// Persists the raw World Cup matches response to disk (shared_preferences) so
/// the app can show data instantly on launch and survive offline / rate limits.
///
/// Every operation is fail-safe: if the platform plugin is unavailable for any
/// reason, caching is silently skipped and the app falls back to the network
/// rather than erroring.
class MatchesCache {
  static const _kData = 'wc_matches_json';
  static const _kFetchedAt = 'wc_matches_fetched_at';

  Future<RawCache?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kData);
      final millis = prefs.getInt(_kFetchedAt);
      if (json == null || millis == null) return null;
      return RawCache(json, DateTime.fromMillisecondsSinceEpoch(millis));
    } catch (e) {
      debugPrint('MatchesCache.read skipped: $e');
      return null;
    }
  }

  Future<void> write(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kData, json);
      await prefs.setInt(_kFetchedAt, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('MatchesCache.write skipped: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kData);
      await prefs.remove(_kFetchedAt);
    } catch (e) {
      debugPrint('MatchesCache.clear skipped: $e');
    }
  }
}
