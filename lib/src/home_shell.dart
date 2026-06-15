import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/competitions/competitions_providers.dart';
import 'features/competitions/presentation/leagues_screen.dart';
import 'features/knockout/presentation/knockout_screen.dart';
import 'features/matches/presentation/matches_screen.dart';
import 'features/standings/presentation/standings_screen.dart';

/// Top-level shell with bottom navigation. The Bracket tab only appears for
/// competitions that have a knockout stage (cups); leagues hide it.
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
      if (showBracket) const KnockoutScreen(),
      LeaguesScreen(onPicked: () => setState(() => _index = 0)),
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
      if (showBracket)
        const NavigationDestination(
          icon: Icon(Icons.account_tree_outlined),
          selectedIcon: Icon(Icons.account_tree),
          label: 'Bracket',
        ),
      const NavigationDestination(
        icon: Icon(Icons.emoji_events_outlined),
        selectedIcon: Icon(Icons.emoji_events),
        label: 'Leagues',
      ),
    ];

    // Guard against the selected index going out of range when the Bracket tab
    // appears/disappears as the competition changes.
    if (_index >= pages.length) _index = 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
