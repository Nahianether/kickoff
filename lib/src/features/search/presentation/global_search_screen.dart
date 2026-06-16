import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../../competitions/presentation/competition_emblem.dart';
import '../../matches/data/models/team.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../team/presentation/team_screen.dart';
import '../application/search_provider.dart';

/// App-wide team search across every league that's been loaded. Matches by
/// name, short name or three-letter code; tapping a result switches to that
/// team's league and opens its page.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(Team t, String q) =>
      t.name.toLowerCase().contains(q) ||
      (t.shortName?.toLowerCase().contains(q) ?? false) ||
      (t.tla?.toLowerCase().contains(q) ?? false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(allCachedTeamsProvider);
    final q = _query.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        flexibleSpace: const HeaderGradient(),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.titleMedium,
          cursorColor: theme.colorScheme.primary,
          decoration: InputDecoration(
            hintText: 'Search teams across leagues…',
            border: InputBorder.none,
            hintStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: all.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Hint(
          icon: Icons.search_off,
          text: 'Search is unavailable right now.',
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return const _Hint(
              icon: Icons.travel_explore_outlined,
              text:
                  'Open a league’s Matches once to include its teams in search.',
            );
          }
          if (q.isEmpty) {
            return const _Hint(
              icon: Icons.search,
              text: 'Search any team across the leagues you’ve opened.',
            );
          }
          final results =
              teams.where((e) => _matches(e.team, q)).toList();
          if (results.isEmpty) {
            return _Hint(
              icon: Icons.search_off,
              text: 'No teams found for “$_query”.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: results.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
            itemBuilder: (context, i) {
              final r = results[i];
              return ListTile(
                leading: TeamCrest(team: r.team, size: 34),
                title: Text(
                  r.team.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    CompetitionEmblem(competition: r.competition, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      r.competition.shortName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  // Open the team scoped to its own league without changing the
                  // user's currently-selected league.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeamScreen(
                          team: r.team, competition: r.competition),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
