import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/football_loader.dart';
import '../../../core/widgets/section_header.dart';
import '../../matches/providers.dart';
import '../application/standings_provider.dart';
import '../data/standing_row.dart';
import '../../matches/presentation/widgets/team_crest.dart';

/// Group standings, computed from results. One table per group.
class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandTitle(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchesProvider.notifier).refresh(),
        child: standings.when(
          loading: () => const AppLoader(message: 'Loading standings…'),
          error: (err, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Could not load standings.\n$err',
                  textAlign: TextAlign.center)),
            ],
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('No group data yet.')),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              children: [
                const _Legend(),
                for (final entry in groups.entries)
                  _GroupTable(groupCode: entry.key, rows: entry.value),
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
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
          Text(
            'Top two of each group advance to the knockouts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTable extends StatelessWidget {
  const _GroupTable({required this.groupCode, required this.rows});

  final String groupCode;
  final List<StandingRow> rows;

  String get _title {
    final parts = groupCode.split('_');
    return parts.length >= 2 ? 'Group ${parts.last.toUpperCase()}' : groupCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _headerRow(theme),
            const Divider(height: 1),
            for (var i = 0; i < rows.length; i++)
              _dataRow(context, theme, i + 1, rows[i]),
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

  Widget _dataRow(BuildContext context, ThemeData theme, int pos, StandingRow r) {
    final qualifying = pos <= 2; // top 2 advance from each group
    final numStyle = theme.textTheme.bodySmall;
    Widget n(int v, {bool bold = false}) => Text(
          v.toString(),
          style: numStyle?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        );

    return _row(
      color: qualifying
          ? theme.colorScheme.primary.withValues(alpha: 0.06)
          : null,
      pos: Text(
        pos.toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: qualifying ? theme.colorScheme.primary : null,
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
