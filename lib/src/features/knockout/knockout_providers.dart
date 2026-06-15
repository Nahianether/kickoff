import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../matches/data/models/match_fixture.dart';
import '../matches/providers.dart';

/// One round of the knockout stage (e.g. Round of 16) with its matches.
class KnockoutRound {
  final String stage;
  final String label;
  final List<MatchFixture> matches;

  const KnockoutRound({
    required this.stage,
    required this.label,
    required this.matches,
  });
}

/// Display order for knockout stages. Membership here also defines what counts
/// as a knockout stage, so non-knockout stages (GROUP_STAGE, LEAGUE_STAGE) are
/// excluded from the bracket.
const Map<String, int> _stageOrder = {
  'PLAY_OFFS': 0,
  'PLAYOFFS': 0,
  'LAST_32': 1,
  'LAST_16': 2,
  'QUARTER_FINALS': 3,
  'SEMI_FINALS': 4,
  'THIRD_PLACE': 5,
  'FINAL': 6,
};

String knockoutStageLabel(String stage) {
  switch (stage) {
    case 'PLAY_OFFS':
    case 'PLAYOFFS':
      return 'Play-offs';
    case 'LAST_32':
      return 'Round of 32';
    case 'LAST_16':
      return 'Round of 16';
    case 'QUARTER_FINALS':
      return 'Quarter-finals';
    case 'SEMI_FINALS':
      return 'Semi-finals';
    case 'THIRD_PLACE':
      return 'Third place';
    case 'FINAL':
      return 'Final';
    default:
      // Fallback: "SOME_STAGE" -> "Some Stage".
      return stage
          .split('_')
          .map((w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
  }
}

/// The knockout bracket derived from the loaded matches: any match that isn't a
/// group-stage game, grouped by stage and ordered from first round to final.
final knockoutProvider = Provider<AsyncValue<List<KnockoutRound>>>((ref) {
  final asyncMatches = ref.watch(matchesProvider);
  return asyncMatches.whenData((data) {
    final byStage = <String, List<MatchFixture>>{};
    for (final m in data.matches) {
      // Only true knockout stages (excludes GROUP_STAGE and the Champions
      // League LEAGUE_STAGE, which belong in standings, not the bracket).
      if (!_stageOrder.containsKey(m.stage)) continue;
      byStage.putIfAbsent(m.stage, () => []).add(m);
    }

    final rounds = byStage.entries.map((e) {
      final matches = e.value..sort((a, b) => a.utcDate.compareTo(b.utcDate));
      return KnockoutRound(
        stage: e.key,
        label: knockoutStageLabel(e.key),
        matches: matches,
      );
    }).toList()
      ..sort((a, b) =>
          (_stageOrder[a.stage] ?? 99).compareTo(_stageOrder[b.stage] ?? 99));

    return rounds;
  });
});
