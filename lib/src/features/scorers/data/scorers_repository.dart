import 'dart:convert';

import '../../../core/api/football_api_client.dart';
import '../../matches/data/matches_cache.dart';
import 'scorer.dart';

/// Cached scorers plus a freshness verdict. Scorers change slowly (only as
/// matches are played), so a generous TTL protects the free-tier quota.
class CachedScorers {
  final List<Scorer> scorers;
  final DateTime fetchedAt;

  const CachedScorers({required this.scorers, required this.fetchedAt});

  Duration get age => DateTime.now().difference(fetchedAt);
  bool get isFresh => age < const Duration(minutes: 30);
}

/// Loads a competition's top scorers from the API with per-competition disk
/// caching.
class ScorersRepository {
  ScorersRepository(this._client, this._cache);

  final FootballApiClient _client;
  final FootballCache _cache;

  String _cacheKey(String code) => 'scorers_$code';

  Future<CachedScorers?> readCache(String code) async {
    final raw = await _cache.read(_cacheKey(code));
    if (raw == null) return null;
    try {
      final scorers = _parse(jsonDecode(raw.json) as Map<String, dynamic>);
      return CachedScorers(scorers: scorers, fetchedAt: raw.fetchedAt);
    } catch (_) {
      return null; // corrupt cache — ignore and refetch
    }
  }

  Future<List<Scorer>> fetchFromApiAndCache(String code) async {
    final json = await _client.getCompetitionScorers(code);
    await _cache.write(_cacheKey(code), jsonEncode(json));
    return _parse(json);
  }

  List<Scorer> _parse(Map<String, dynamic> json) {
    final list = (json['scorers'] as List<dynamic>? ?? const []);
    return list
        .map((e) => Scorer.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
