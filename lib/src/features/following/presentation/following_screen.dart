import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../competitions/competitions_providers.dart';
import '../../competitions/data/competition.dart';
import '../../competitions/presentation/competition_emblem.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../team/presentation/team_screen.dart';
import '../application/following_provider.dart';

/// A hub for the teams the user follows, grouped by league. Each team shows its
/// next fixture (or latest result) pulled from that league's cache. Tapping a
/// team switches to its league and opens its page.
class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(followingFeedProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        flexibleSpace: const HeaderGradient(),
        title: const Text('Following'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(followingFeedProvider),
        child: feed.when(
          loading: () => const _Skeleton(),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text('Could not load: $e')),
          ]),
          data: (leagues) {
            if (leagues.isEmpty) return const _EmptyView();
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                for (final league in leagues) _LeagueGroup(league: league),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LeagueGroup extends ConsumerWidget {
  const _LeagueGroup({required this.league});

  final FollowingLeague league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final competition = league.competition;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            child: Row(
              children: [
                if (competition != null) ...[
                  CompetitionEmblem(competition: competition, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  competition?.shortName ?? 'Other',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${league.teams.length}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (league.notLoaded) ...[
                  const Spacer(),
                  Text(
                    'open to load fixtures',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < league.teams.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: scheme.outlineVariant),
                  _TeamTile(entry: league.teams[i], competition: competition),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends ConsumerWidget {
  const _TeamTile({required this.entry, required this.competition});

  final FollowingTeam entry;
  final Competition? competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final team = entry.team;
    return ListTile(
      leading: TeamCrest(team: team.toTeam(), size: 34),
      title: Text(
        team.displayName,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: _subtitle(theme),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: competition == null
          ? null
          : () {
              // Switch the app to this team's league, then open its page so the
              // standings/fixtures shown are for the right competition.
              ref
                  .read(selectedCompetitionProvider.notifier)
                  .select(competition!);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeamScreen(team: team.toTeam()),
                ),
              );
            },
    );
  }

  Widget _subtitle(ThemeData theme) {
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final next = entry.next;
    if (next != null) {
      final opp = next.homeTeam.id == entry.team.id ? next.awayTeam : next.homeTeam;
      return Text(
        'Next: ${opp.displayName} · ${DateFormat('EEE d MMM, h:mm a').format(next.utcDate)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: muted,
      );
    }

    final last = entry.last;
    if (last != null) {
      final isHome = last.homeTeam.id == entry.team.id;
      final opp = isHome ? last.awayTeam : last.homeTeam;
      final mine = isHome ? last.score.homeFullTime : last.score.awayFullTime;
      final theirs = isHome ? last.score.awayFullTime : last.score.homeFullTime;
      final result = (mine == null || theirs == null)
          ? '?'
          : mine > theirs
              ? 'W'
              : mine < theirs
                  ? 'L'
                  : 'D';
      final color = switch (result) {
        'W' => theme.colorScheme.primary,
        'L' => AppTheme.live,
        _ => scheme.onSurfaceVariant,
      };
      return Row(
        children: [
          _resultDot(result, color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Last: $mine–$theirs vs ${opp.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ),
        ],
      );
    }

    return Text('No fixtures cached yet', style: muted);
  }

  Widget _resultDot(String letter, Color color) => Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 110),
        Icon(Icons.star_outline_rounded,
            size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You’re not following any teams yet.\nOpen a match or a team and tap Follow — they’ll appear here grouped by league.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          for (var g = 0; g < 2; g++) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 12, 6, 10),
              child: SkeletonBox(width: 120, height: 14),
            ),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          SkeletonBox(
                              width: 34, height: 34, shape: BoxShape.circle),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 120, height: 12),
                                SizedBox(height: 7),
                                SkeletonBox(width: 180, height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
