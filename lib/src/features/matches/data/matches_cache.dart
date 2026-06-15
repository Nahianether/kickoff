import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A previously stored API response plus when it was fetched.
class RawCache {
  final String json;
  final DateTime fetchedAt;
  const RawCache(this.json, this.fetchedAt);
}

/// Persists raw API responses to disk (shared_preferences) keyed by a logical
/// name (e.g. "matches_PL", "standings_CL") so each competition caches
/// independently. This lets the app show data instantly on launch and survive
/// offline / rate limits.
///
/// Every operation is fail-safe: if the platform plugin is unavailable for any
/// reason, caching is silently skipped and the app falls back to the network
/// rather than erroring.
class FootballCache {
  String _dataKey(String key) => 'cache_data_$key';
  String _fetchedAtKey(String key) => 'cache_at_$key';

  Future<RawCache?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_dataKey(key));
      final millis = prefs.getInt(_fetchedAtKey(key));
      if (json == null || millis == null) return null;
      return RawCache(json, DateTime.fromMillisecondsSinceEpoch(millis));
    } catch (e) {
      debugPrint('FootballCache.read skipped: $e');
      return null;
    }
  }

  Future<void> write(String key, String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dataKey(key), json);
      await prefs.setInt(
          _fetchedAtKey(key), DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('FootballCache.write skipped: $e');
    }
  }

  Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dataKey(key));
      await prefs.remove(_fetchedAtKey(key));
    } catch (e) {
      debugPrint('FootballCache.clear skipped: $e');
    }
  }
}
