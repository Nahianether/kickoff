import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../competitions/data/competition.dart';
import '../../matches/data/models/team.dart';
import '../../matches/providers.dart';

/// A team paired with the league it appears in (a team can show up in more than
/// one, e.g. a club in both its domestic league and the Champions League).
class TeamInLeague {
  final Team team;
  final Competition competition;
  const TeamInLeague(this.team, this.competition);
}

/// Every team found in the on-disk match cache across all competitions, so the
/// user can search teams app-wide. Reads cache only (no network); a league only
/// contributes teams once its matches have been loaded at least once.
final allCachedTeamsProvider = FutureProvider<List<TeamInLeague>>((ref) async {
  final repo = ref.watch(matchesRepositoryProvider);
  final result = <TeamInLeague>[];

  for (final competition in Competition.all) {
    final cached = await repo.readCache(competition.code);
    if (cached == null) continue;
    final seen = <int>{};
    for (final match in cached.matches) {
      for (final team in [match.homeTeam, match.awayTeam]) {
        final id = team.id;
        if (id == null || seen.contains(id)) continue;
        seen.add(id);
        result.add(TeamInLeague(team, competition));
      }
    }
  }
  return result;
});
