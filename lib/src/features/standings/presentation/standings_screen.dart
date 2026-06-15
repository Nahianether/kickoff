import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/football_loader.dart';
import '../../../core/widgets/section_header.dart';
import '../../competitions/competitions_providers.dart';
import '../../competitions/data/competition.dart';
import '../../competitions/presentation/competition_title.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../application/standings_provider.dart';
import '../data/standing_row.dart';

/// Standings for the selected competition: a single league table, group tables
/// (World Cup), or the Champions League "league phase" — whatever the API
/// returns. Qualifying rows are highlighted.
class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider);
    final competition = ref.watch(selectedCompetitionProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        flexibleSpace: const HeaderGradient(),
        title: const CompetitionAppBarTitle(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(standingsProvider),
        child: standings.when(
          loading: () => const AppLoader(message: 'Loading standings…'),
          error: (err, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text('Could not load standings.\n$err',
                      textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          data: (tables) {
            if (tables.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No standings available yet.')),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              children: [
                _Legend(text: qualifyingLegend(competition)),
                for (final table in tables)
                  _StandingsCard(
                    competition: competition,
                    table: table,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Small legend explaining the highlighted qualifying rows.
class _Legend extends StatelessWidget {
  const _Legend({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              border: Border.all(color: scheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsCard extends StatelessWidget {
  const _StandingsCard({required this.competition, required this.table});

  final Competition competition;
  final StandingsTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advance = qualifyingCount(competition, table);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Card(
        child: Column(
          children: [
            if (table.label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    table.label!,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
            _headerRow(theme),
            const Divider(height: 1),
            for (final r in table.rows)
              _dataRow(context, theme, r, qualifying: r.position <= advance),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Column layout shared by header and data rows.
  Widget _row({
    required Widget pos,
    required Widget team,
    required List<Widget> stats,
    Color? color,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: pos)),
          const SizedBox(width: 4),
          Expanded(child: team),
          for (final s in stats) SizedBox(width: 30, child: Center(child: s)),
        ],
      ),
    );
  }

  Widget _headerRow(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );
    Widget h(String t) => Text(t, style: style);
    return _row(
      pos: h('#'),
      team: h('Team'),
      stats: [h('P'), h('W'), h('D'), h('L'), h('GD'), h('Pts')],
    );
  }

  Widget _dataRow(BuildContext context, ThemeData theme, StandingRow r,
      {required bool qualifying}) {
    final numStyle = theme.textTheme.bodySmall;
    Widget n(int v, {bool bold = false}) => Text(
          v.toString(),
          style: numStyle?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        );

    final scheme = theme.colorScheme;
    return _row(
      color: qualifying ? scheme.primary.withValues(alpha: 0.07) : null,
      pos: qualifying
          ? Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 1.2),
              ),
              child: Text(
                r.position.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            )
          : Text(
              r.position.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
      team: Row(
        children: [
          TeamCrest(team: r.team, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              r.team.displayName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      stats: [
        n(r.played),
        n(r.won),
        n(r.drawn),
        n(r.lost),
        Text(
          (r.goalDifference > 0 ? '+' : '') + r.goalDifference.toString(),
          style: numStyle,
        ),
        n(r.points, bold: true),
      ],
    );
  }
}
