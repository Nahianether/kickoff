import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/competitions/competitions_providers.dart';
import 'features/knockout/presentation/knockout_screen.dart';
import 'features/matches/presentation/matches_screen.dart';
import 'features/scorers/presentation/scorers_screen.dart';
import 'features/standings/presentation/standings_screen.dart';

/// Top-level shell with bottom navigation. League switching, search, following
/// and settings live in the shared top bar (see `LeagueAppBar`), so the bottom
/// bar stays focused on content. The Bracket tab only appears for competitions
/// that have a knockout stage (cups).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final competition = ref.watch(selectedCompetitionProvider);
    final showBracket = competition.hasKnockout;

    final pages = <Widget>[
      const MatchesScreen(),
      const StandingsScreen(),
      const ScorersScreen(),
      if (showBracket) const KnockoutScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.sports_soccer_outlined),
        selectedIcon: Icon(Icons.sports_soccer),
        label: 'Matches',
      ),
      const NavigationDestination(
        icon: Icon(Icons.table_chart_outlined),
        selectedIcon: Icon(Icons.table_chart),
        label: 'Standings',
      ),
      const NavigationDestination(
        icon: Icon(Icons.military_tech_outlined),
        selectedIcon: Icon(Icons.military_tech),
        label: 'Scorers',
      ),
      if (showBracket)
        const NavigationDestination(
          icon: Icon(Icons.account_tree_outlined),
          selectedIcon: Icon(Icons.account_tree),
          label: 'Bracket',
        ),
    ];

    // Guard against the selected index going out of range when the Bracket tab
    // appears/disappears as the competition changes.
    if (_index >= pages.length) _index = 0;

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: destinations,
        ),
      ),
    );
  }
}
