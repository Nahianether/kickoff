import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/section_header.dart';
import '../../favourites/favourites_providers.dart';
import '../../matches/presentation/widgets/team_crest.dart';

/// App settings: appearance (theme) and management of followed teams.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final groups = ref.watch(favouritesByLeagueProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        flexibleSpace: const HeaderGradient(),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _sectionLabel(theme, 'Appearance'),
          Card(
            child: Column(
              children: [
                _ThemeOption(
                  label: 'System default',
                  subtitle: 'Match your device setting',
                  icon: Icons.brightness_auto_outlined,
                  selected: mode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.system),
                ),
                _optionDivider(theme),
                _ThemeOption(
                  label: 'Dark',
                  subtitle: 'The signature black & teal look',
                  icon: Icons.dark_mode_outlined,
                  selected: mode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.dark),
                ),
                _optionDivider(theme),
                _ThemeOption(
                  label: 'Light',
                  subtitle: 'Bright off-white surfaces',
                  icon: Icons.light_mode_outlined,
                  selected: mode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.light),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(theme, 'Followed teams'),
          if (groups.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.star_outline_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No teams followed yet. Open a match or team and tap Follow to add one.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // One card per league, so it's clear which teams you follow where.
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                child: Text(
                  group.competition?.shortName ?? 'Other',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < group.teams.length; i++) ...[
                      if (i > 0) _optionDivider(theme),
                      ListTile(
                        leading:
                            TeamCrest(team: group.teams[i].toTeam(), size: 32),
                        title: Text(
                          group.teams[i].displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.star_rounded),
                          color: const Color(0xFFE0A714),
                          tooltip: 'Unfollow',
                          onPressed: () => ref
                              .read(favouriteTeamsProvider.notifier)
                              .remove(group.teams[i].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _optionDivider(ThemeData theme) =>
      Divider(height: 1, color: theme.colorScheme.outlineVariant);
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : Icon(Icons.circle_outlined, color: scheme.outlineVariant),
    );
  }
}
