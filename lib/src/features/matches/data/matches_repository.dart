import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/api/api_config.dart';
import '../../../core/api/football_api_client.dart';
import 'matches_cache.dart';
import 'models/match_fixture.dart';

/// Cached matches plus a freshness verdict used to decide whether to revalidate.
class CachedMatches {
  final List<MatchFixture> matches;
  final DateTime fetchedAt;

  const CachedMatches({required this.matches, required this.fetchedAt});

  Duration get age => DateTime.now().difference(fetchedAt);

  /// While a match is live we want fresh scores; otherwise we can hold longer
  /// to protect the free-tier quota.
  bool get isFresh {
    final hasLive = matches.any((m) => m.isLive);
    final ttl =
        hasLive ? const Duration(minutes: 1) : const Duration(minutes: 5);
    return age < ttl;
  }
}

/// Loads World Cup matches from the live API (with disk caching) or, when no API
/// key is configured, from a bundled sample file.
class MatchesRepository {
  MatchesRepository(this._client, this._cache);

  final FootballApiClient _client;
  final MatchesCache _cache;

  /// True when results come from the bundled sample (no API key configured).
  bool get usingSampleData => !ApiConfig.hasKey;

  /// Reads the bundled sample fixtures (used when there is no API key).
  Future<List<MatchFixture>> loadSample() async {
    final raw = await rootBundle.loadString('assets/data/sample_matches.json');
    return _parseMatches(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Returns the cached matches if any have been stored, else null.
  Future<CachedMatches?> readCache() async {
    final raw = await _cache.read();
    if (raw == null) return null;
    try {
      final matches =
          _parseMatches(jsonDecode(raw.json) as Map<String, dynamic>);
      return CachedMatches(matches: matches, fetchedAt: raw.fetchedAt);
    } catch (_) {
      return null; // corrupt cache — ignore and refetch
    }
  }

  /// Fetches from the API and writes the raw response to the cache.
  Future<List<MatchFixture>> fetchFromApiAndCache() async {
    final json = await _client.getCompetitionMatches(ApiConfig.worldCupCode);
    await _cache.write(jsonEncode(json));
    return _parseMatches(json);
  }

  List<MatchFixture> _parseMatches(Map<String, dynamic> json) {
    final list = (json['matches'] as List<dynamic>? ?? const []);
    final matches = list
        .map((e) => MatchFixture.fromJson(e as Map<String, dynamic>))
        .toList();
    matches.sort((a, b) => a.utcDate.compareTo(b.utcDate));
    return matches;
  }
}
