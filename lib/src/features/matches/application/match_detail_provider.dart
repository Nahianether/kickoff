import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_config.dart';
import '../data/models/match_detail.dart';
import '../providers.dart';

/// Fetches richer detail for a single match (`/matches/{id}`), cached on disk.
///
/// Cache-first: a played match's detail doesn't change, so we serve any cached
/// copy and only hit the network when nothing is stored — protecting the free
/// tier's request quota. Returns null when there is no API key (e.g. the bundled
/// World Cup sample), so the screen simply shows the base facts.
final matchDetailProvider =
    FutureProvider.family<MatchDetail?, int>((ref, matchId) async {
  final cache = ref.watch(footballCacheProvider);
  final key = 'match_$matchId';

  final cached = await cache.read(key);
  if (cached != null) {
    try {
      return MatchDetail.fromJson(jsonDecode(cached.json) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt cache — fall through to a fresh fetch.
    }
  }

  if (!ApiConfig.hasKey) return null;

  final client = ref.watch(footballApiClientProvider);
  final json = await client.getMatch(matchId);
  await cache.write(key, jsonEncode(json));
  return MatchDetail.fromJson(json);
});
