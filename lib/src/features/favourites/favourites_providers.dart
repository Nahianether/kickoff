import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../matches/data/models/team.dart';
import 'data/favourite_team.dart';

const _kFavouritesKey = 'favourite_teams';

/// The user's starred teams, persisted locally. Used to filter the Matches list
/// to followed teams and to highlight their rows in Standings.
///
/// Loads asynchronously on first build (seeded empty); the brief empty state is
/// harmless because favourites only add a filter/highlight on top of data that
/// renders regardless.
class FavouritesNotifier extends Notifier<List<FavouriteTeam>> {
  @override
  List<FavouriteTeam> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kFavouritesKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => FavouriteTeam.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (e) {
      debugPrint('Favourites load skipped: $e');
    }
  }

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

  /// Stars [team] if it isn't already a favourite, otherwise removes it.
  /// Teams without an id (undecided knockout slots) are ignored.
  void toggle(Team team) {
    final fav = FavouriteTeam.fromTeam(team);
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
