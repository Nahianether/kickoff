import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../competitions_providers.dart';
import '../data/competition.dart';
import 'competition_emblem.dart';

/// The Leagues hub: pick a competition to view its matches, standings and
/// (for cups) bracket. Selecting one switches the active competition and jumps
/// back to the Matches tab via [onPicked].
class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key, required this.onPicked});

  /// Called after a competition is selected (used to switch to the Matches tab).
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCompetitionProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandTitle(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Text(
              'Competitions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final competition in Competition.all)
            _CompetitionTile(
              competition: competition,
              selected: competition.code == selected.code,
              onTap: () {
                ref
                    .read(selectedCompetitionProvider.notifier)
                    .select(competition);
                onPicked();
              },
            ),
        ],
      ),
    );
  }
}

class _CompetitionTile extends StatelessWidget {
  const _CompetitionTile({
    required this.competition,
    required this.selected,
    required this.onTap,
  });

  final Competition competition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: CompetitionEmblem(competition: competition, size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competition.shortName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            competition.country,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (competition.hasKnockout)
                            _tag(theme, 'Cup')
                          else
                            _tag(theme, 'League'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: scheme.primary, size: 22)
                else
                  Icon(Icons.chevron_right,
                      color: scheme.onSurfaceVariant, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(ThemeData theme, String text) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
