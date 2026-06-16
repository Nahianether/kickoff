import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../../following/presentation/following_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../competitions_providers.dart';
import '../data/competition.dart';
import 'competition_emblem.dart';

/// The shared top bar for every content screen: a tappable league switcher on
/// the left and the global actions (search, following, settings) on the right.
/// Pass [bottom] for screens that need a sub-row (e.g. the Matches filter).
class LeagueAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LeagueAppBar({super.key, this.bottom});

  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 12,
      flexibleSpace: const HeaderGradient(),
      title: const LeagueSwitcherTitle(),
      actions: [
        _action(context, Icons.search_rounded, 'Search teams',
            () => const GlobalSearchScreen()),
        _action(context, Icons.star_rounded, 'Following',
            () => const FollowingScreen()),
        _action(context, Icons.settings_rounded, 'Settings',
            () => const SettingsScreen()),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String tooltip,
    Widget Function() screen,
  ) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen()),
      ),
    );
  }
}

/// The active league shown as a tappable pill (emblem + name + chevron). Tapping
/// opens the league switcher sheet.
class LeagueSwitcherTitle extends ConsumerWidget {
  const LeagueSwitcherTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final competition = ref.watch(selectedCompetitionProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showLeagueSwitcher(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompetitionEmblem(competition: competition, size: 26),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    competition.shortName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    competition.country,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Opens the bottom sheet for switching the active league.
Future<void> showLeagueSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _LeagueSwitcherSheet(),
  );
}

class _LeagueSwitcherSheet extends ConsumerWidget {
  const _LeagueSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = ref.watch(selectedCompetitionProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'Choose a league',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final c in Competition.all)
              _SwitcherTile(
                competition: c,
                current: c.code == current.code,
                onTap: () {
                  ref
                      .read(selectedCompetitionProvider.notifier)
                      .select(c);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                'The app reopens to the league you last viewed.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitcherTile extends StatelessWidget {
  const _SwitcherTile({
    required this.competition,
    required this.current,
    required this.onTap,
  });

  final Competition competition;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: current
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                CompetitionEmblem(competition: competition, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competition.shortName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: current ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      Text(
                        '${competition.country} · '
                        '${competition.hasKnockout ? 'Cup' : 'League'}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (current)
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
