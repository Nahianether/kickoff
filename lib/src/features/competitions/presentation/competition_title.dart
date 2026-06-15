import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../competitions_providers.dart';
import 'competition_emblem.dart';

/// App-bar title showing the active competition's emblem and name. Used across
/// the Matches, Standings and Bracket screens so it's clear which competition
/// is being viewed.
class CompetitionAppBarTitle extends ConsumerWidget {
  const CompetitionAppBarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final competition = ref.watch(selectedCompetitionProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompetitionEmblem(competition: competition, size: 26),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                competition.shortName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  height: 1.05,
                ),
              ),
              Text(
                competition.country,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
