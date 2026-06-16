import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../competitions/competitions_providers.dart';
import '../../favourites/favourites_providers.dart';
import '../../team/presentation/team_screen.dart';
import '../application/match_detail_provider.dart';
import '../data/models/match_detail.dart';
import '../data/models/match_fixture.dart';
import '../data/models/team.dart';
import 'widgets/status_chip.dart';
import 'widgets/team_crest.dart';

/// Full match preview: big scoreline / kickoff, key facts, and (when the API
/// provides them) matchday, competition, officials and how the result was
/// decided. Each team can be followed from here.
class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.match});

  final MatchFixture match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detail = ref.watch(matchDetailProvider(match.id));

    return Scaffold(
      appBar: AppBar(title: Text(match.stageLabel)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _header(context, ref, theme),
          const SizedBox(height: 20),
          _factsCard(context, theme),
          // Extra detail loads in from /matches/{id}; failures are silent — the
          // base facts above always render.
          detail.maybeWhen(
            data: (d) => (d != null && d.hasExtraInfo)
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _DetailFacts(detail: d),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
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
  Widget _header(BuildContext context, WidgetRef ref, ThemeData theme) {
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
              Expanded(child: _teamBlock(context, ref, match.homeTeam)),
              _centerScore(theme),
              Expanded(child: _teamBlock(context, ref, match.awayTeam)),
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

  Widget _teamBlock(BuildContext context, WidgetRef ref, Team team) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: team.id == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TeamScreen(team: team)),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                TeamCrest(team: team, size: 72),
                const SizedBox(height: 10),
                Text(
                  team.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (team.id != null) ...[
          const SizedBox(height: 8),
          _FollowButton(team: team),
        ],
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

/// A compact toggle that follows/unfollows a team straight from the header.
class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFav = ref.watch(favouriteTeamIdsProvider).contains(team.id);
    final code = ref.watch(selectedCompetitionProvider).code;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ref
            .read(favouriteTeamsProvider.notifier)
            .toggle(team, competitionCode: code);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(isFav
                  ? 'Unfollowed ${team.displayName}'
                  : 'Following ${team.displayName}'),
            ),
          );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFav
              ? AppTheme.amber.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFav ? AppTheme.amber : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: isFav ? AppTheme.amber : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              isFav ? 'Following' : 'Follow',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    isFav ? AppTheme.amber : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extra facts from `/matches/{id}`: matchday, competition, officials and how
/// the result was decided.
class _DetailFacts extends StatelessWidget {
  const _DetailFacts({required this.detail});

  final MatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];

    void add(IconData icon, String label, String value) {
      if (rows.isNotEmpty) {
        rows.add(Divider(height: 1, color: theme.colorScheme.outlineVariant));
      }
      rows.add(_row(theme, icon, label, value));
    }

    if (detail.durationLabel != null) {
      add(Icons.sports_score_outlined, 'Result', detail.durationLabel!);
    }
    if (detail.competitionName != null) {
      add(Icons.shield_outlined, 'Competition', detail.competitionName!);
    }
    if (detail.matchday != null) {
      add(Icons.numbers_outlined, 'Matchday', 'Matchday ${detail.matchday}');
    }
    final ref = detail.mainReferee;
    if (ref != null) {
      final n = ref.nationality;
      add(Icons.sports_outlined, 'Referee',
          n != null ? '${ref.name} · $n' : ref.name);
    }
    if (detail.lastUpdated != null) {
      add(Icons.update_outlined, 'Updated',
          DateFormat('d MMM yyyy · h:mm a').format(detail.lastUpdated!));
    }

    return Card(child: Column(children: rows));
  }

  Widget _row(ThemeData theme, IconData icon, String label, String value) {
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
}
