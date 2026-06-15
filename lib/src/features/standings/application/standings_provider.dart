import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../competitions/competitions_providers.dart';
import '../../competitions/data/competition.dart';
import '../../matches/providers.dart';
import '../data/standing_row.dart';
import '../data/standings_repository.dart';

final standingsRepositoryProvider = Provider<StandingsRepository>((ref) {
  return StandingsRepository(
    ref.watch(footballApiClientProvider),
    ref.watch(footballCacheProvider),
  );
});

/// Standings for the currently selected competition.
///
/// Live path: read the per-competition disk cache, serve it if fresh, otherwise
/// fetch from the API (falling back to the stale cache on failure). No-key World
/// Cup path: compute group tables from the bundled sample matches.
///
/// Rebuilds automatically when the selected competition changes.
final standingsProvider =
    FutureProvider<List<StandingsTable>>((ref) async {
  final competition = ref.watch(selectedCompetitionProvider);
  final code = competition.code;
  final repo = ref.watch(standingsRepositoryProvider);

  // No API key → only the World Cup has data (computed from sample matches).
  final matchesRepo = ref.watch(matchesRepositoryProvider);
  if (matchesRepo.usesSample(competition)) {
    final matches = await matchesRepo.loadSample();
    return computeStandingsFromMatches(matches);
  }

  final cached = await repo.readCache(code);
  if (cached != null && cached.isFresh) return cached.tables;

  try {
    return await repo.fetchAndCache(code);
  } catch (e) {
    if (cached != null) return cached.tables; // serve stale on failure
    rethrow;
  }
});

/// How many top rows of a table qualify (for the highlight + legend), based on
/// competition type and the kind of table.
int qualifyingCount(Competition competition, StandingsTable table) {
  // World Cup groups: top 2 advance.
  if (competition.code == Competition.worldCup.code) return 2;
  // Champions League league phase: top 8 advance directly to the last 16.
  if (competition.code == Competition.championsLeague.code) return 8;
  // Domestic leagues: top 4 (Champions League qualification spots).
  return 4;
}

/// Short legend text describing what the highlight means for [competition].
String qualifyingLegend(Competition competition) {
  if (competition.code == Competition.worldCup.code) {
    return 'Top two of each group advance to the knockouts';
  }
  if (competition.code == Competition.championsLeague.code) {
    return 'Top eight advance directly to the round of 16';
  }
  return 'Top four qualify for the Champions League';
}
