import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../competitions/competitions_providers.dart';
import '../../favourites/favourites_providers.dart';
import '../../matches/data/models/match_fixture.dart';
import '../../matches/data/models/team.dart';
import '../../matches/presentation/match_detail_screen.dart';
import '../../matches/presentation/widgets/match_card.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../matches/providers.dart';
import '../../standings/application/standings_provider.dart';
import '../../standings/data/standing_row.dart';

/// A team's page scoped to the competition currently being viewed: its
/// standings row plus its results and upcoming fixtures, drawn entirely from
/// data already loaded for that competition (no extra API calls). Cross-
/// competition history isn't available on the free API tier.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key, required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competition = ref.watch(selectedCompetitionProvider);
    final matchesAsync = ref.watch(matchesProvider);
    final standingsAsync = ref.watch(standingsProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 8,
        flexibleSpace: const HeaderGradient(),
        title: Row(
          children: [
            TeamCrest(team: team, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(team.displayName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          _Header(team: team),
          const SizedBox(height: 4),
          standingsAsync.maybeWhen(
            data: (tables) {
              final row = _findRow(tables, team.id);
              return row != null
                  ? _StandingCard(competition: competition.shortName, row: row)
                  : const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
          matchesAsync.when(
            loading: () => const _MatchesSkeleton(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Could not load matches.\n$e')),
            ),
            data: (data) => _matchSections(context, data.matches),
          ),
        ],
      ),
    );
  }

  StandingRow? _findRow(List<StandingsTable> tables, int? teamId) {
    if (teamId == null) return null;
    for (final t in tables) {
      for (final r in t.rows) {
        if (r.team.id == teamId) return r;
      }
    }
    return null;
  }

  Widget _matchSections(BuildContext context, List<MatchFixture> all) {
    final id = team.id;
    final mine = id == null
        ? <MatchFixture>[]
        : all
            .where((m) => m.homeTeam.id == id || m.awayTeam.id == id)
            .toList();

    if (mine.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
        child: Center(
          child: Text(
            'No matches for ${team.displayName} in this competition.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Upcoming/live ascending (next first); results descending (latest first).
    final upcoming = mine.where((m) => !m.isFinished).toList()
      ..sort((a, b) => a.utcDate.compareTo(b.utcDate));
    final results = mine.where((m) => m.isFinished).toList()
      ..sort((a, b) => b.utcDate.compareTo(a.utcDate));

    return Column(
      children: [
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(label: 'Fixtures', count: upcoming.length),
          for (final m in upcoming) _card(context, m),
        ],
        if (results.isNotEmpty) ...[
          _SectionHeader(label: 'Results', count: results.length),
          for (final m in results) _card(context, m),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, MatchFixture m) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        child: MatchCard(
          match: m,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)),
          ),
        ),
      );
}

/// Big crest, name and a Follow toggle.
class _Header extends ConsumerWidget {
  const _Header({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFav = team.id != null &&
        ref.watch(favouriteTeamIdsProvider).contains(team.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary.withValues(alpha: 0.16), scheme.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          TeamCrest(team: team, size: 76),
          const SizedBox(height: 12),
          Text(
            team.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (team.id != null) ...[
            const SizedBox(height: 14),
            _FollowButton(team: team, isFav: isFav),
          ],
        ],
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.team, required this.isFav});

  final Team team;
  final bool isFav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        ref.read(favouriteTeamsProvider.notifier).toggle(team);
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isFav
              ? AppTheme.amber.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isFav ? AppTheme.amber : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18,
              color: isFav ? AppTheme.amber : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              isFav ? 'Following' : 'Follow',
              style: theme.textTheme.labelLarge?.copyWith(
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

/// The team's row in the current competition's table.
class _StandingCard extends StatelessWidget {
  const _StandingCard({required this.competition, required this.row});

  final String competition;
  final StandingRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget stat(String label, String value, {bool primary = false}) => Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: primary ? scheme.primary : scheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
    final gd = (row.goalDifference > 0 ? '+' : '') + row.goalDifference.toString();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$competition · Position ${row.position}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  stat('PL', row.played.toString()),
                  stat('W', row.won.toString()),
                  stat('D', row.drawn.toString()),
                  stat('L', row.lost.toString()),
                  stat('GD', gd),
                  stat('PTS', row.points.toString(), primary: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesSkeleton extends StatelessWidget {
  const _MatchesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 22, 6, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 120, height: 12),
            ),
          ),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Expanded(child: SkeletonBox(height: 14)),
                      SizedBox(width: 16),
                      SkeletonBox(width: 48, height: 22, radius: 8),
                      SizedBox(width: 16),
                      Expanded(child: SkeletonBox(height: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
