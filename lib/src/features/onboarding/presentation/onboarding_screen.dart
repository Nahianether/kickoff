import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../competitions/competitions_providers.dart';
import '../../competitions/data/competition.dart';
import '../../competitions/presentation/competition_emblem.dart';
import '../../favourites/favourites_providers.dart';
import '../../matches/data/models/team.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../standings/application/standings_provider.dart';
import '../onboarding_providers.dart';

/// First-run flow: pick a default league, then optionally follow some of its
/// teams. Either step can be skipped — finishing or skipping marks onboarding
/// done so it never shows again.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  late String _selectedCode = ref.read(selectedCompetitionProvider).code;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingDoneProvider.notifier).complete();

  void _goToTeams() {
    // Set the chosen league as the current (persisted) league before loading
    // its teams.
    final competition =
        Competition.byCode(_selectedCode) ?? Competition.fallback;
    ref.read(selectedCompetitionProvider.notifier).select(competition);
    setState(() => _page = 1);
    _pages.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _LeagueStep(
                    selectedCode: _selectedCode,
                    onSelect: (c) => setState(() => _selectedCode = c.code),
                  ),
                  _TeamsStep(competitionCode: _selectedCode),
                ],
              ),
            ),
            _Dots(page: _page, count: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _page == 0 ? _goToTeams : _finish,
                  child: Text(_page == 0 ? 'Continue' : 'Start exploring'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueStep extends StatelessWidget {
  const _LeagueStep({required this.selectedCode, required this.onSelect});

  final String selectedCode;
  final ValueChanged<Competition> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        Image.asset('assets/images/logo_new.png', height: 56, width: 56),
        const SizedBox(height: 16),
        Text(
          'Welcome to KickOff',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick the league you follow most. The app will open to it each time — '
          'you can switch or change this anytime.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        for (final c in Competition.all)
          _LeagueTile(
            competition: c,
            selected: c.code == selectedCode,
            onTap: () => onSelect(c),
          ),
      ],
    );
  }
}

class _LeagueTile extends StatelessWidget {
  const _LeagueTile({
    required this.competition,
    required this.selected,
    required this.onTap,
  });

  final Competition competition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                CompetitionEmblem(competition: competition, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competition.shortName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        competition.country,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamsStep extends ConsumerWidget {
  const _TeamsStep({required this.competitionCode});

  final String competitionCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final competition =
        Competition.byCode(competitionCode) ?? Competition.fallback;
    final standings = ref.watch(standingsProvider);
    final favIds = ref.watch(favouriteTeamIdsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        Text(
          'Follow your teams',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Star a few ${competition.shortName} teams for a personalised feed. '
          'Optional — you can follow teams from any match later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        standings.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _laterNote(theme),
          data: (tables) {
            final teams = <int, Team>{};
            for (final t in tables) {
              for (final r in t.rows) {
                final id = r.team.id;
                if (id != null) teams[id] = r.team;
              }
            }
            if (teams.isEmpty) return _laterNote(theme);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final team in teams.values)
                  _TeamChip(
                    team: team,
                    selected: favIds.contains(team.id),
                    onTap: () => ref
                        .read(favouriteTeamsProvider.notifier)
                        .toggle(team, competitionCode: competitionCode),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _laterNote(ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Team list will appear once this league has loaded. You can '
                'follow teams anytime by tapping Follow on a match or team.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamCrest(team: team, size: 22),
            const SizedBox(width: 8),
            Text(
              team.displayName,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == page ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == page ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
