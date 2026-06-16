import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../competitions/data/competition.dart';
import '../../favourites/data/favourite_team.dart';
import '../../favourites/favourites_providers.dart';
import '../../matches/data/models/match_fixture.dart';
import '../../matches/providers.dart';

/// A followed team plus its next upcoming and most recent finished match in its
/// league (or null when that league hasn't been cached yet).
class FollowingTeam {
  final FavouriteTeam team;
  final MatchFixture? next;
  final MatchFixture? last;
  const FollowingTeam({required this.team, this.next, this.last});
}

/// One league's worth of followed teams in the hub.
class FollowingLeague {
  final Competition? competition;
  final List<FollowingTeam> teams;

  /// True when the league's matches haven't been cached yet, so no fixtures can
  /// be shown for its teams.
  final bool notLoaded;

  const FollowingLeague({
    required this.competition,
    required this.teams,
    this.notLoaded = false,
  });
}

/// The Following hub feed: followed teams grouped by league, each annotated with
/// its next/last match read from that league's on-disk cache. Reads cache only
/// (no network), so it stays within the free-tier quota; leagues never opened
/// simply show no fixtures.
final followingFeedProvider = FutureProvider<List<FollowingLeague>>((ref) async {
  final groups = ref.watch(favouritesByLeagueProvider);
  final repo = ref.watch(matchesRepositoryProvider);

  final result = <FollowingLeague>[];
  for (final group in groups) {
    final competition = group.competition;
    if (competition == null) {
      result.add(FollowingLeague(
        competition: null,
        teams: group.teams.map((t) => FollowingTeam(team: t)).toList(),
      ));
      continue;
    }

    final cached = await repo.readCache(competition.code);
    final matches = cached?.matches ?? const <MatchFixture>[];
    final teams = group.teams.map((t) {
      final mine = matches
          .where((m) => m.homeTeam.id == t.id || m.awayTeam.id == t.id)
          .toList();
      final upcoming = mine.where((m) => !m.isFinished).toList()
        ..sort((a, b) => a.utcDate.compareTo(b.utcDate));
      final finished = mine.where((m) => m.isFinished).toList()
        ..sort((a, b) => b.utcDate.compareTo(a.utcDate));
      return FollowingTeam(
        team: t,
        next: upcoming.isNotEmpty ? upcoming.first : null,
        last: finished.isNotEmpty ? finished.first : null,
      );
    }).toList();

    result.add(FollowingLeague(
      competition: competition,
      teams: teams,
      notLoaded: cached == null,
    ));
  }
  return result;
});
