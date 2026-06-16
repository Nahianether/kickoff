import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../favourites/favourites_providers.dart';
import '../../data/models/match_fixture.dart';
import 'status_chip.dart';
import 'team_crest.dart';

/// A tappable card summarising one match: teams, crests, and score or kickoff.
/// Live matches get a red accent; finished matches bold the winner; followed
/// teams show an amber star beside their name.
class MatchCard extends ConsumerWidget {
  const MatchCard({super.key, required this.match, this.onTap});

  final MatchFixture match;
  final VoidCallback? onTap;

  bool _isWinner(bool home) {
    if (!match.isFinished) return false;
    if (match.score.winner == 'HOME_TEAM') return home;
    if (match.score.winner == 'AWAY_TEAM') return !home;
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = match.isLive ? AppTheme.live : scheme.primary;
    final favIds = ref.watch(favouriteTeamIdsProvider);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Subtle red wash behind live matches.
            gradient: match.isLive
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.live.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  )
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status accent stripe.
                Container(width: 3, color: accent.withValues(alpha: 0.85)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 9, 14, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                [match.stageLabel, match.groupLabel]
                                    .whereType<String>()
                                    .join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            StatusChip(match: match),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _teamRow(context, favIds, home: true)),
                            _centerColumn(context),
                            Expanded(child: _teamRow(context, favIds, home: false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamRow(BuildContext context, Set<int> favIds, {required bool home}) {
    final team = home ? match.homeTeam : match.awayTeam;
    final theme = Theme.of(context);
    final winner = _isWinner(home);
    final isFav = team.id != null && favIds.contains(team.id);
    return Column(
      children: [
        TeamCrest(team: team, size: 40),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFav) ...[
              const Icon(Icons.star_rounded, size: 13, color: AppTheme.amber),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                team.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: winner ? FontWeight.w800 : FontWeight.w600,
                  color: winner
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _centerColumn(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.score.hasResult)
            _ScorePill(
              text: '${match.score.homeFullTime}  ${match.score.awayFullTime}',
              live: match.isLive,
            )
          else
            Text(
              DateFormat('h:mm a').format(match.utcDate),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            match.score.hasResult
                ? (match.isLive ? 'LIVE' : 'FT')
                : DateFormat('EEE d MMM').format(match.utcDate),
            style: theme.textTheme.labelSmall?.copyWith(
              color: match.isLive ? AppTheme.live : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The scoreline rendered as a compact pill so it reads as the focal point.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.text, required this.live});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: live
            ? AppTheme.live.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: live ? AppTheme.live : scheme.onSurface,
        ),
      ),
    );
  }
}
