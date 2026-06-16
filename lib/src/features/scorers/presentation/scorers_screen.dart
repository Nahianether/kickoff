import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../competitions/presentation/competition_title.dart';
import '../../favourites/favourites_providers.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../team/presentation/team_screen.dart';
import '../application/scorers_provider.dart';
import '../data/scorer.dart';

/// Top scorers for the selected competition: goals, assists and penalties,
/// ranked. Sourced from `/competitions/{code}/scorers`.
class ScorersScreen extends ConsumerWidget {
  const ScorersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorers = ref.watch(scorersProvider);
    final favIds = ref.watch(favouriteTeamIdsProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        flexibleSpace: const HeaderGradient(),
        title: const CompetitionAppBarTitle(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(scorersProvider),
        child: scorers.when(
          loading: () => const _ScorersSkeleton(),
          error: (err, _) => _ErrorView(message: friendlyError(err)),
          data: (list) {
            if (list.isEmpty) return const _EmptyView();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) return const _Legend();
                final s = list[i - 1];
                return _ScorerCard(
                  rank: i,
                  scorer: s,
                  followed: s.team.id != null && favIds.contains(s.team.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Text(
        'Top scorers · G goals · A assists · P penalties',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ScorerCard extends StatelessWidget {
  const _ScorerCard({
    required this.rank,
    required this.scorer,
    required this.followed,
  });

  final int rank;
  final Scorer scorer;
  final bool followed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: scorer.team.id == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => TeamScreen(team: scorer.team)),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _RankBadge(rank: rank),
            const SizedBox(width: 12),
            TeamCrest(team: scorer.team, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scorer.playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          scorer.team.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (followed) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppTheme.amber),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _stat(theme, scorer.goals.toString(), 'G', primary: true),
            if (scorer.assists != null && scorer.assists! > 0)
              _stat(theme, scorer.assists.toString(), 'A'),
            if (scorer.penalties != null && scorer.penalties! > 0)
              _stat(theme, scorer.penalties.toString(), 'P'),
          ],
        ),
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label,
      {bool primary = false}) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rank chip; medals for the top three.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final medal = switch (rank) {
      1 => const Color(0xFFE0A714), // gold
      2 => const Color(0xFFB8C0C8), // silver
      3 => const Color(0xFFCD7F46), // bronze
      _ => null,
    };
    final color = medal ?? scheme.surfaceContainerHighest;
    final fg = medal != null ? Colors.black : scheme.onSurfaceVariant;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$rank',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _ScorersSkeleton extends StatelessWidget {
  const _ScorersSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const SkeletonBox(
                    width: 26, height: 26, shape: BoxShape.circle),
                const SizedBox(width: 12),
                const SkeletonBox(
                    width: 30, height: 30, shape: BoxShape.circle),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 130, height: 12),
                      SizedBox(height: 7),
                      SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
                const SkeletonBox(width: 18, height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 110),
        Icon(Icons.sports_soccer,
            size: 44, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No scorer data available yet.\nAdd an API key, or check back once the season is under way.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Could not load scorers.\n$message',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
