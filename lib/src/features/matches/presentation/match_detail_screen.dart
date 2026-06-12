import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/match_fixture.dart';
import 'widgets/status_chip.dart';
import 'widgets/team_crest.dart';

/// Full match preview: big scoreline / kickoff, plus key facts.
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});

  final MatchFixture match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(match.stageLabel)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _header(context, theme),
          const SizedBox(height: 20),
          _factsCard(context, theme),
          if (match.score.hasHalfTime) ...[
            const SizedBox(height: 16),
            _halfTimeCard(context, theme),
          ],
          if (!match.isFinished) ...[
            const SizedBox(height: 16),
            _previewNote(context, theme),
          ],
        ],
      ),
    );
  }

  /// Premium gradient header with group/status, crests and the scoreline.
  Widget _header(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary.withValues(alpha: 0.18), scheme.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (match.groupLabel != null) _pill(theme, match.groupLabel!),
              const Spacer(),
              StatusChip(match: match),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _teamBlock(
                      context, match.homeTeam.displayName, match.homeTeam)),
              _centerScore(theme),
              Expanded(
                  child: _teamBlock(
                      context, match.awayTeam.displayName, match.awayTeam)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, String text) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _centerScore(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.score.hasResult)
            Text(
              '${match.score.homeFullTime} - ${match.score.awayFullTime}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          else ...[
            Text(
              DateFormat('h:mm a').format(match.utcDate),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'VS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamBlock(BuildContext context, String name, team) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TeamCrest(team: team, size: 72),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _factsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          _factRow(theme, Icons.emoji_events_outlined, 'Stage',
              [match.stageLabel, match.groupLabel].whereType<String>().join(' · ')),
          _divider(theme),
          _factRow(theme, Icons.event_outlined, 'Kick-off',
              DateFormat('EEEE, d MMM yyyy · h:mm a').format(match.utcDate)),
          if (match.venue != null) ...[
            _divider(theme),
            _factRow(theme, Icons.stadium_outlined, 'Venue', match.venue!),
          ],
        ],
      ),
    );
  }

  Widget _halfTimeCard(BuildContext context, ThemeData theme) {
    return Card(
      child: _factRow(
        theme,
        Icons.timelapse_outlined,
        'Half-time',
        '${match.score.homeHalfTime} - ${match.score.awayHalfTime}',
      ),
    );
  }

  Widget _previewNote(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_soccer, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Match preview — kick-off ${_relativeKickoff()}. Check back for the live score.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeKickoff() {
    final now = DateTime.now();
    final diff = match.utcDate.difference(now);
    if (diff.isNegative) return 'soon';
    if (diff.inDays >= 1) return 'in ${diff.inDays} day(s)';
    if (diff.inHours >= 1) return 'in ${diff.inHours} hour(s)';
    return 'in ${diff.inMinutes} minute(s)';
  }

  Widget _factRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) =>
      Divider(height: 1, color: theme.colorScheme.outlineVariant);
}
