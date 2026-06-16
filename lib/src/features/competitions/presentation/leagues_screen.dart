import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../../favourites/favourites_providers.dart';
import '../../following/presentation/following_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../competitions_providers.dart';
import '../data/competition.dart';
import 'competition_emblem.dart';

/// The Leagues hub: pick a competition to view its matches, standings and
/// (for cups) bracket. Tapping a league views it; the star sets it as the
/// default the app opens to on every launch.
class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key, required this.onPicked});

  /// Called after a competition is selected (used to switch to the Matches tab).
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedCompetitionProvider);
    final defaultComp = ref.watch(defaultCompetitionProvider);
    final followCount = ref.watch(favouriteTeamsProvider).length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        flexibleSpace: const HeaderGradient(),
        title: const BrandTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search teams',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.star_outline_rounded),
            tooltip: 'Following',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FollowingScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.star_rounded,
                    color: const Color(0xFFE0A714), size: 28),
                title: Text(
                  'Following',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  followCount == 0
                      ? 'Follow teams to see them grouped by league'
                      : '$followCount team${followCount == 1 ? '' : 's'} across your leagues',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FollowingScreen()),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 2),
            child: Text(
              'Competitions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Tap to view · star sets your default league',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final competition in Competition.all)
            _CompetitionTile(
              competition: competition,
              isViewing: competition.code == selected.code,
              isDefault: competition.code == defaultComp.code,
              onTap: () {
                ref
                    .read(selectedCompetitionProvider.notifier)
                    .select(competition);
                onPicked();
              },
              onSetDefault: () => ref
                  .read(defaultCompetitionProvider.notifier)
                  .setDefault(competition),
            ),
        ],
      ),
    );
  }
}

class _CompetitionTile extends StatelessWidget {
  const _CompetitionTile({
    required this.competition,
    required this.isViewing,
    required this.isDefault,
    required this.onTap,
    required this.onSetDefault,
  });

  final Competition competition;
  final bool isViewing;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isViewing ? scheme.primary : scheme.outlineVariant,
            width: isViewing ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: CompetitionEmblem(competition: competition, size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              competition.shortName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            _defaultPill(theme),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            competition.country,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _tag(theme, competition.hasKnockout ? 'Cup' : 'League'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onSetDefault,
                  tooltip: isDefault
                      ? 'Your default league'
                      : 'Set as default league',
                  icon: Icon(
                    isDefault ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isDefault ? const Color(0xFFE0A714) : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultPill(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Default',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tag(ThemeData theme, String text) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
