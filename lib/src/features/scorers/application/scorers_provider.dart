import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_config.dart';
import '../../competitions/competitions_providers.dart';
import '../../matches/providers.dart';
import '../data/scorer.dart';
import '../data/scorers_repository.dart';

final scorersRepositoryProvider = Provider<ScorersRepository>((ref) {
  return ScorersRepository(
    ref.watch(footballApiClientProvider),
    ref.watch(footballCacheProvider),
  );
});

/// Top scorers for the selected competition. Cache-first with stale fallback:
/// show cached data instantly and revalidate only when stale; if the network
/// fails, keep the cached copy. Returns an empty list when there is no API key
/// (scorers aren't available offline), which the screen shows as an empty state.
final scorersProvider = FutureProvider<List<Scorer>>((ref) async {
  final competition = ref.watch(selectedCompetitionProvider);
  final code = competition.code;
  final repo = ref.watch(scorersRepositoryProvider);

  if (!ApiConfig.hasKey) return const [];

  final cached = await repo.readCache(code);
  if (cached != null && cached.isFresh) return cached.scorers;

  try {
    return await repo.fetchFromApiAndCache(code);
  } catch (e) {
    // Network/quota failure — fall back to any cached copy, however stale.
    if (cached != null) return cached.scorers;
    rethrow;
  }
});
