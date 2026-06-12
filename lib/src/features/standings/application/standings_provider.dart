import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matches/data/models/match_fixture.dart';
import '../../matches/data/models/team.dart';
import '../../matches/providers.dart';
import '../data/standing_row.dart';

/// Computes group standings from the loaded matches.
///
/// Only group-stage matches are considered. Finished matches contribute to the
/// stats; upcoming matches still register the teams so every group lists its
/// participants even before kickoff.
Map<String, List<StandingRow>> computeStandings(List<MatchFixture> matches) {
  // group key -> (team key -> row)
  final groups = <String, Map<String, StandingRow>>{};

  String teamKey(Team t) => t.id?.toString() ?? t.name;

  for (final m in matches) {
    final group = m.group;
    if (group == null) continue; // skip knockout matches

    final table = groups.putIfAbsent(group, () => {});
    final home = table.putIfAbsent(
        teamKey(m.homeTeam), () => StandingRow(team: m.homeTeam));
    final away = table.putIfAbsent(
        teamKey(m.awayTeam), () => StandingRow(team: m.awayTeam));

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

  // Sort rows within each group (simplified FIFA order:
  // points -> goal difference -> goals for -> name).
  final result = <String, List<StandingRow>>{};
  final sortedGroupKeys = groups.keys.toList()..sort();
  for (final key in sortedGroupKeys) {
    final rows = groups[key]!.values.toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        final byGd = b.goalDifference.compareTo(a.goalDifference);
        if (byGd != 0) return byGd;
        final byGf = b.goalsFor.compareTo(a.goalsFor);
        if (byGf != 0) return byGf;
        return a.team.displayName.compareTo(b.team.displayName);
      });
    result[key] = rows;
  }
  return result;
}

/// Per-group standings derived from [matchesProvider]. Keyed by API group code
/// (e.g. "GROUP_A"), each value already sorted for display.
final standingsProvider =
    Provider<AsyncValue<Map<String, List<StandingRow>>>>((ref) {
  final asyncMatches = ref.watch(matchesProvider);
  return asyncMatches.whenData((data) => computeStandings(data.matches));
});
