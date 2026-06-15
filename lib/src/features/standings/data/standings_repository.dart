import 'dart:convert';

import '../../../core/api/football_api_client.dart';
import '../../matches/data/matches_cache.dart';
import '../../matches/data/models/match_fixture.dart';
import '../../matches/data/models/team.dart';
import 'standing_row.dart';

/// Cached standings plus a freshness verdict.
class CachedStandings {
  final List<StandingsTable> tables;
  final DateTime fetchedAt;

  const CachedStandings({required this.tables, required this.fetchedAt});

  // Standings change slowly; a 5-minute TTL keeps us well within the free tier.
  bool get isFresh =>
      DateTime.now().difference(fetchedAt) < const Duration(minutes: 5);
}

/// Loads a competition's standings from the API (with per-competition disk
/// caching). The API serves league tables, group tables and the Champions
/// League "league phase" through the same endpoint, so one parser handles all.
class StandingsRepository {
  StandingsRepository(this._client, this._cache);

  final FootballApiClient _client;
  final FootballCache _cache;

  String _cacheKey(String code) => 'standings_$code';

  Future<CachedStandings?> readCache(String code) async {
    final raw = await _cache.read(_cacheKey(code));
    if (raw == null) return null;
    try {
      final tables = _parse(jsonDecode(raw.json) as Map<String, dynamic>);
      return CachedStandings(tables: tables, fetchedAt: raw.fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<List<StandingsTable>> fetchAndCache(String code) async {
    final json = await _client.getCompetitionStandings(code);
    await _cache.write(_cacheKey(code), jsonEncode(json));
    return _parse(json);
  }

  List<StandingsTable> _parse(Map<String, dynamic> json) {
    final standings = (json['standings'] as List<dynamic>? ?? const []);
    final tables = <StandingsTable>[];
    for (final entry in standings.cast<Map<String, dynamic>>()) {
      // Skip the HOME/AWAY split tables; we only show the overall (TOTAL) one.
      if ((entry['type'] as String?) != 'TOTAL') continue;
      final rows = (entry['table'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(StandingRow.fromJson)
          .toList();
      if (rows.isEmpty) continue;
      tables.add(StandingsTable(
        label: _label(entry['group'] as String?),
        rows: rows,
      ));
    }
    return tables;
  }

  /// "GROUP_A" -> "Group A"; "League phase" -> as-is; null -> null.
  String? _label(String? group) {
    if (group == null || group.isEmpty) return null;
    if (group.toUpperCase().startsWith('GROUP_')) {
      return 'Group ${group.split('_').last.toUpperCase()}';
    }
    return group;
  }
}

/// Builds group standings from already-loaded matches. Used only as the no-key
/// World Cup fallback (the live API path uses the standings endpoint instead).
List<StandingsTable> computeStandingsFromMatches(List<MatchFixture> matches) {
  final groups = <String, Map<String, _Acc>>{};
  String teamKey(Team t) => t.id?.toString() ?? t.name;

  for (final m in matches) {
    final group = m.group;
    if (group == null) continue; // skip knockout matches
    final table = groups.putIfAbsent(group, () => {});
    final home = table.putIfAbsent(teamKey(m.homeTeam), () => _Acc(m.homeTeam));
    final away = table.putIfAbsent(teamKey(m.awayTeam), () => _Acc(m.awayTeam));
    if (!m.isFinished || !m.score.hasResult) continue;

    final hg = m.score.homeFullTime!;
    final ag = m.score.awayFullTime!;
    home.played++;
    away.played++;
    home.goalsFor += hg;
    home.goalsAgainst += ag;
    away.goalsFor += ag;
    away.goalsAgainst += hg;
    if (hg > ag) {
      home.won++;
      away.lost++;
    } else if (hg < ag) {
      away.won++;
      home.lost++;
    } else {
      home.drawn++;
      away.drawn++;
    }
  }

  final result = <StandingsTable>[];
  final sortedGroupKeys = groups.keys.toList()..sort();
  for (final key in sortedGroupKeys) {
    final accs = groups[key]!.values.toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        final byGd = b.goalDifference.compareTo(a.goalDifference);
        if (byGd != 0) return byGd;
        final byGf = b.goalsFor.compareTo(a.goalsFor);
        if (byGf != 0) return byGf;
        return a.team.displayName.compareTo(b.team.displayName);
      });
    final parts = key.split('_');
    final label = parts.length >= 2 ? 'Group ${parts.last.toUpperCase()}' : key;
    result.add(StandingsTable(
      label: label,
      rows: [
        for (var i = 0; i < accs.length; i++) accs[i].toRow(i + 1),
      ],
    ));
  }
  return result;
}

/// Mutable accumulator used while computing sample standings.
class _Acc {
  _Acc(this.team);
  final Team team;
  int played = 0, won = 0, drawn = 0, lost = 0, goalsFor = 0, goalsAgainst = 0;

  int get goalDifference => goalsFor - goalsAgainst;
  int get points => won * 3 + drawn;

  StandingRow toRow(int position) => StandingRow(
        position: position,
        team: team,
        played: played,
        won: won,
        drawn: drawn,
        lost: lost,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
        goalDifference: goalDifference,
        points: points,
      );
}
