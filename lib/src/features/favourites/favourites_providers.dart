import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../competitions/data/competition.dart';
import '../matches/data/models/team.dart';
import 'data/favourite_team.dart';

const _kFavouritesKey = 'favourite_teams';

/// Reads the persisted followed teams before the first frame (called in `main`),
/// so they're available synchronously — no in-build async state mutation.
Future<List<FavouriteTeam>> loadFavourites() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFavouritesKey);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => FavouriteTeam.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('loadFavourites skipped: $e');
    return const [];
  }
}

/// Seed for [favouriteTeamsProvider]; overridden in `main` with the saved list.
final bootstrapFavouritesProvider =
    Provider<List<FavouriteTeam>>((ref) => const []);

/// The user's starred teams, persisted locally. Seeded synchronously at boot
/// (via [bootstrapFavouritesProvider]) so reading it never schedules a state
/// change during a widget build.
class FavouritesNotifier extends Notifier<List<FavouriteTeam>> {
  @override
  List<FavouriteTeam> build() => ref.read(bootstrapFavouritesProvider);

  Future<void> _persist(List<FavouriteTeam> teams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kFavouritesKey,
        jsonEncode(teams.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Favourites persist skipped: $e');
    }
  }

  bool isFavourite(int? id) =>
      id != null && state.any((t) => t.id == id);

  /// Stars [team] if it isn't already a favourite, otherwise removes it. When
  /// adding, the team is tagged with [competitionCode] (the league it was
  /// followed from) so favourites can be grouped by league. Teams without an id
  /// (undecided knockout slots) are ignored.
  void toggle(Team team, {String competitionCode = ''}) {
    final fav = FavouriteTeam.fromTeam(team, competitionCode: competitionCode);
    if (fav == null) return;
    final exists = state.any((t) => t.id == fav.id);
    final next = exists
        ? state.where((t) => t.id != fav.id).toList()
        : [...state, fav];
    state = next;
    _persist(next);
  }

  void remove(int id) {
    final next = state.where((t) => t.id != id).toList();
    state = next;
    _persist(next);
  }
}

final favouriteTeamsProvider =
    NotifierProvider<FavouritesNotifier, List<FavouriteTeam>>(
  FavouritesNotifier.new,
);

/// Just the set of favourite team ids — convenient for fast membership checks
/// in list/standings rows.
final favouriteTeamIdsProvider = Provider<Set<int>>((ref) {
  return ref.watch(favouriteTeamsProvider).map((t) => t.id).toSet();
});

/// Followed teams belonging to one league. [competition] is null for teams
/// whose origin league is unknown (e.g. saved before league tagging existed).
class FavouritesGroup {
  final Competition? competition;
  final List<FavouriteTeam> teams;
  const FavouritesGroup(this.competition, this.teams);
}

/// Followed teams grouped by the league they were followed from, ordered like
/// [Competition.all], with any untagged teams last under a null competition.
final favouritesByLeagueProvider = Provider<List<FavouritesGroup>>((ref) {
  final favs = ref.watch(favouriteTeamsProvider);
  final byCode = <String, List<FavouriteTeam>>{};
  for (final f in favs) {
    byCode.putIfAbsent(f.competitionCode, () => []).add(f);
  }

  final groups = <FavouritesGroup>[];
  for (final c in Competition.all) {
    final list = byCode[c.code];
    if (list != null && list.isNotEmpty) groups.add(FavouritesGroup(c, list));
  }

  // Anything tagged with an unknown/empty code goes into a trailing bucket.
  final known = Competition.all.map((c) => c.code).toSet();
  final others = <FavouriteTeam>[];
  byCode.forEach((code, list) {
    if (!known.contains(code)) others.addAll(list);
  });
  if (others.isNotEmpty) groups.add(FavouritesGroup(null, others));

  return groups;
});
