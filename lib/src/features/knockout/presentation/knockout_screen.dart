import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/football_loader.dart';
import '../../../core/widgets/section_header.dart';
import '../../competitions/presentation/competition_title.dart';
import '../../matches/data/models/match_fixture.dart';
import '../../matches/presentation/match_detail_screen.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../matches/providers.dart';
import '../knockout_providers.dart';

/// The knockout bracket: each round is a column, scrollable horizontally.
class KnockoutScreen extends ConsumerWidget {
  const KnockoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knockout = ref.watch(knockoutProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        flexibleSpace: const HeaderGradient(),
        title: const CompetitionAppBarTitle(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchesProvider.notifier).refresh(),
        child: knockout.when(
          loading: () => const AppLoader(message: 'Loading bracket…'),
          error: (err, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text('Could not load bracket.\n$err',
                textAlign: TextAlign.center)),
          ]),
          data: (rounds) {
            if (rounds.isEmpty) return const _EmptyBracket();
            return _Bracket(rounds: rounds);
          },
        ),
      ),
    );
  }
}

class _EmptyBracket extends StatelessWidget {
  const _EmptyBracket();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.account_tree_outlined,
            size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The knockout bracket appears once the group stage is complete.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({required this.rounds});

  final List<KnockoutRound> rounds;

  @override
  Widget build(BuildContext context) {
    // A ListView so pull-to-refresh works, holding a horizontal scroll of rounds.
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final round in rounds) _RoundColumn(round: round),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({required this.round});

  final KnockoutRound round;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 232,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Text(
                  round.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${round.matches.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final m in round.matches) _KnockoutTile(match: m),
        ],
      ),
    );
  }
}

class _KnockoutTile extends StatelessWidget {
  const _KnockoutTile({required this.match});

  final MatchFixture match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  match.isFinished
                      ? 'Full-time'
                      : DateFormat('d MMM · h:mm a').format(match.utcDate),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _teamLine(theme, match.homeTeam.displayName, match.homeTeam,
                    match.score.homeFullTime, _isWinner(true)),
                const SizedBox(height: 6),
                _teamLine(theme, match.awayTeam.displayName, match.awayTeam,
                    match.score.awayFullTime, _isWinner(false)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isWinner(bool home) {
    if (!match.isFinished) return false;
    if (match.score.winner == 'HOME_TEAM') return home;
    if (match.score.winner == 'AWAY_TEAM') return !home;
    return false;
  }

  Widget _teamLine(ThemeData theme, String name, team, int? goals, bool winner) {
    return Row(
      children: [
        TeamCrest(team: team, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
              color: winner ? theme.colorScheme.onSurface : null,
            ),
          ),
        ),
        if (goals != null)
          Text(
            '$goals',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: winner ? FontWeight.bold : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
