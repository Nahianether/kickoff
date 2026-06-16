import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/api/football_api_client.dart';
import '../competitions/competitions_providers.dart';
import '../favourites/favourites_providers.dart';
import 'data/matches_cache.dart';
import 'data/matches_repository.dart';
import 'data/models/match_fixture.dart';
import 'data/models/team.dart';

/// Which subset of matches the user is currently viewing.
enum MatchFilter {
  all('All'),
  upcoming('Fixtures'),
  results('Results'),
  live('Live'),
  favourites('★');

  const MatchFilter(this.label);
  final String label;
}

/// The matches plus metadata about where they came from and when.
class MatchesData {
  final List<MatchFixture> matches;
  final DateTime fetchedAt;

  /// True when these matches were loaded from the on-disk cache rather than a
  /// fresh network response.
  final bool fromCache;

  /// Set when a pull-to-refresh failed but we kept showing existing data.
  final String? refreshError;

  const MatchesData({
    required this.matches,
    required this.fetchedAt,
    this.fromCache = false,
    this.refreshError,
  });

  MatchesData copyWith({bool? fromCache, String? refreshError}) => MatchesData(
        matches: matches,
        fetchedAt: fetchedAt,
        fromCache: fromCache ?? this.fromCache,
        refreshError: refreshError,
      );
}

final footballApiClientProvider = Provider<FootballApiClient>((ref) {
  final client = FootballApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final footballCacheProvider = Provider<FootballCache>((ref) => FootballCache());

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(
    ref.watch(footballApiClientProvider),
    ref.watch(footballCacheProvider),
  );
});

/// Owns the smart caching policy for the currently selected competition:
///  - launch / switch → show cache instantly, revalidate only if stale
///  - refresh → always hit the API, fall back to cache on failure
///  - otherwise the in-memory value is reused (no API calls on tab/filter changes)
///
/// Rebuilds automatically whenever the selected competition changes.
class MatchesNotifier extends AsyncNotifier<MatchesData> {
  MatchesRepository get _repo => ref.read(matchesRepositoryProvider);

  @override
  Future<MatchesData> build() async {
    final competition = ref.watch(selectedCompetitionProvider);
    final code = competition.code;

    // No API key → only the World Cup has bundled sample data.
    if (_repo.usesSample(competition)) {
      final matches = await _repo.loadSample();
      return MatchesData(
        matches: matches,
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
    }

    final cached = await _repo.readCache(code);
    if (cached != null) {
      // Stale-while-revalidate: show cache now, refresh in the background only
      // when it has gone stale.
      if (!cached.isFresh) {
        _revalidateSilently(code);
      }
      return MatchesData(
        matches: cached.matches,
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }

    // Nothing cached yet → must fetch.
    return _fetch(code);
  }

  Future<MatchesData> _fetch(String code) async {
    final matches = await _repo.fetchFromApiAndCache(code);
    return MatchesData(
      matches: matches,
      fetchedAt: DateTime.now(),
      fromCache: false,
    );
  }

  /// Background refresh that never throws — keeps cached data on failure.
  Future<void> _revalidateSilently(String code) async {
    try {
      state = AsyncData(await _fetch(code));
    } catch (_) {
      // Ignore: the cached data is still on screen.
    }
  }

  /// Pull-to-refresh. Always calls the API; on failure keeps the current data
  /// visible and records the error so the UI can surface it.
  Future<void> refresh() async {
    final code = ref.read(selectedCompetitionProvider).code;
    try {
      state = AsyncData(await _fetch(code));
    } catch (e, st) {
      final prev = state.value;
      if (prev != null) {
        state = AsyncData(prev.copyWith(refreshError: friendlyError(e)));
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final matchesProvider =
    AsyncNotifierProvider<MatchesNotifier, MatchesData>(MatchesNotifier.new);

/// True when the current competition's results come from the bundled sample
/// (no API key configured and viewing the World Cup).
final usingSampleDataProvider = Provider<bool>((ref) {
  final competition = ref.watch(selectedCompetitionProvider);
  return ref.watch(matchesRepositoryProvider).usesSample(competition);
});

/// Holds the currently selected filter tab.
class MatchFilterNotifier extends Notifier<MatchFilter> {
  @override
  MatchFilter build() => MatchFilter.all;

  void select(MatchFilter filter) => state = filter;
}

final matchFilterProvider =
    NotifierProvider<MatchFilterNotifier, MatchFilter>(MatchFilterNotifier.new);

/// The current team search query (empty when not searching).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

bool _teamMatchesQuery(Team t, String q) {
  return t.name.toLowerCase().contains(q) ||
      (t.shortName?.toLowerCase().contains(q) ?? false) ||
      (t.tla?.toLowerCase().contains(q) ?? false);
}

/// Matches after applying the search query (when present) or the selected
/// filter. A non-empty search overrides the status filter so a team's full
/// schedule is shown.
final filteredMatchesProvider = Provider<AsyncValue<List<MatchFixture>>>((ref) {
  final filter = ref.watch(matchFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final favIds = ref.watch(favouriteTeamIdsProvider);
  final asyncMatches = ref.watch(matchesProvider);
  return asyncMatches.whenData((data) {
    final matches = data.matches;
    if (query.isNotEmpty) {
      return matches
          .where((m) =>
              _teamMatchesQuery(m.homeTeam, query) ||
              _teamMatchesQuery(m.awayTeam, query))
          .toList();
    }
    return switch (filter) {
      MatchFilter.all => matches,
      MatchFilter.upcoming => matches.where((m) => m.isUpcoming).toList(),
      MatchFilter.results => matches.where((m) => m.isFinished).toList(),
      MatchFilter.live => matches.where((m) => m.isLive).toList(),
      MatchFilter.favourites => matches
          .where((m) =>
              favIds.contains(m.homeTeam.id) || favIds.contains(m.awayTeam.id))
          .toList(),
    };
  });
});
