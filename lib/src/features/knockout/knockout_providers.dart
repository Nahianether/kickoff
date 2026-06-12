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

/// Display order and labels for knockout stages.
const Map<String, int> _stageOrder = {
  'LAST_32': 0,
  'LAST_16': 1,
  'QUARTER_FINALS': 2,
  'SEMI_FINALS': 3,
  'THIRD_PLACE': 4,
  'FINAL': 5,
};

String knockoutStageLabel(String stage) {
  switch (stage) {
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
      if (m.group != null) continue; // skip group-stage matches
      if (m.stage == 'GROUP_STAGE') continue;
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
