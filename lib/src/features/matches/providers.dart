import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/api/football_api_client.dart';
import '../competitions/competitions_providers.dart';
import '../competitions/data/competition.dart';
import '../favourites/favourites_providers.dart';
import 'data/matches_cache.dart';
import 'data/matches_repository.dart';
import 'data/models/match_fixture.dart';

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

  /// Leagues already revalidated against the network in this app session.
  /// Persists for the life of the process (static), so the first time a league
  /// is shown after launch we always refresh — correcting stale "live"/score
  /// statuses carried over in the cache from the previous session — while later
  /// in-session switches between leagues respect the cache TTL to save quota.
  static final Set<String> _revalidatedThisSession = <String>{};

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
      final firstViewThisSession = !_revalidatedThisSession.contains(code);
      _revalidatedThisSession.add(code);

      // On the first view of a league this session, a cached "live" match is
      // almost certainly stale — the match finished while the app was closed.
      // Block briefly on a fresh fetch so we never flash a phantom "LIVE"; if
      // the network or rate-limit fails, fall through to the cache (the
      // retrying background refresh below then heals it).
      if (firstViewThisSession && cached.matches.any((m) => m.isLive)) {
        try {
          return await _fetch(code);
        } catch (_) {
          // Fall through to showing the cache + a background retry.
        }
      }

      // Stale-while-revalidate: show cache now, refresh in the background on the
      // first view this session or whenever the cache has gone stale.
      if (firstViewThisSession || !cached.isFresh) {
        _revalidateSilently(code);
      }
      return MatchesData(
        matches: cached.matches,
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }

    // Nothing cached yet → must fetch.
    _revalidatedThisSession.add(code);
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
  ///
  /// Retries a few times with a delay: on a cold start the app fires several
  /// requests at once (matches, standings, scorers, …) which can trip the free
  /// tier's 10-requests/minute limit (429). Without a retry the refresh would
  /// give up and leave a stale "LIVE" status on screen until a manual pull. The
  /// delays let the rate-limit window free a slot so the data self-heals.
  Future<void> _revalidateSilently(String code) async {
    const delays = [Duration(seconds: 6), Duration(seconds: 8)];
    for (var attempt = 0;; attempt++) {
      try {
        final fresh = await _fetch(code);
        // The user may have switched leagues while we were fetching — never
        // overwrite the now-selected league's data with this one's.
        if (ref.read(selectedCompetitionProvider).code != code) return;
        state = AsyncData(fresh);
        return;
      } catch (_) {
        if (attempt >= delays.length) return; // give up quietly; cache stays
        await Future.delayed(delays[attempt]);
        if (ref.read(selectedCompetitionProvider).code != code) return;
      }
    }
  }

  /// Pull-to-refresh. Always calls the API; on failure keeps the current data
  /// visible and records the error so the UI can surface it.
  Future<void> refresh() async {
    final code = ref.read(selectedCompetitionProvider).code;
    _revalidatedThisSession.add(code);
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

/// Matches for a specific competition (by code), independent of the currently
/// selected league. Cache-first (serves any cached copy without blocking on the
/// network) so screens like the team page can show another league's fixtures
/// without changing the user's selection. Falls back to a fetch when nothing is
/// cached, and to the bundled sample for the no-key World Cup.
final competitionMatchesProvider =
    FutureProvider.family<List<MatchFixture>, String>((ref, code) async {
  final competition = Competition.byCode(code) ?? Competition.fallback;
  final repo = ref.watch(matchesRepositoryProvider);
  if (repo.usesSample(competition)) return repo.loadSample();
  final cached = await repo.readCache(code);
  if (cached != null) return cached.matches;
  return repo.fetchFromApiAndCache(code);
});

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

/// The single day the user has pinned in the matches view, or null for the
/// default "all dates". Normalised to midnight so only the calendar day matters.
class SelectedDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime date) => state = DateTime(date.year, date.month, date.day);

  void clear() => state = null;
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime?>(SelectedDateNotifier.new);

/// Matches for the current competition after applying the selected status
/// filter and, if one is pinned, the selected day (team lookup lives in the
/// global search screen instead).
final filteredMatchesProvider = Provider<AsyncValue<List<MatchFixture>>>((ref) {
  final filter = ref.watch(matchFilterProvider);
  final favIds = ref.watch(favouriteTeamIdsProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final asyncMatches = ref.watch(matchesProvider);
  return asyncMatches.whenData((data) {
    var matches = switch (filter) {
      MatchFilter.all => data.matches,
      MatchFilter.upcoming => data.matches.where((m) => m.isUpcoming).toList(),
      MatchFilter.results => data.matches.where((m) => m.isFinished).toList(),
      MatchFilter.live => data.matches.where((m) => m.isLive).toList(),
      MatchFilter.favourites => data.matches
          .where((m) =>
              favIds.contains(m.homeTeam.id) || favIds.contains(m.awayTeam.id))
          .toList(),
    };
    if (selectedDate != null) {
      // utcDate is stored as local time, so compare against the local day.
      matches = matches
          .where((m) =>
              m.utcDate.year == selectedDate.year &&
              m.utcDate.month == selectedDate.month &&
              m.utcDate.day == selectedDate.day)
          .toList();
    }
    return matches;
  });
});
