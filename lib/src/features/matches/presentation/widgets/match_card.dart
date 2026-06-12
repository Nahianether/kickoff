import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/match_fixture.dart';
import 'status_chip.dart';
import 'team_crest.dart';

/// A tappable card summarising one match: teams, crests, and score or kickoff.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.onTap});

  final MatchFixture match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [match.stageLabel, match.groupLabel]
                          .whereType<String>()
                          .join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  StatusChip(match: match),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _teamRow(context, home: true)),
                  _centerColumn(context),
                  Expanded(child: _teamRow(context, home: false)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(BuildContext context, {required bool home}) {
    final team = home ? match.homeTeam : match.awayTeam;
    final theme = Theme.of(context);
    return Column(
      children: [
        TeamCrest(team: team, size: 38),
        const SizedBox(height: 6),
        Text(
          team.displayName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _centerColumn(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.score.hasResult)
            Text(
              '${match.score.homeFullTime} - ${match.score.awayFullTime}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              DateFormat('HH:mm').format(match.utcDate),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            match.score.hasResult
                ? 'FT'
                : DateFormat('EEE d MMM').format(match.utcDate),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
