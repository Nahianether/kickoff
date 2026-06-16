import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../competitions/competitions_providers.dart';
import '../../competitions/presentation/competition_title.dart';
import '../data/models/match_fixture.dart';
import '../providers.dart';
import 'match_detail_screen.dart';
import 'widgets/match_card.dart';
import 'widgets/segmented_filter.dart';

/// Home screen: World Cup fixtures & results with a segmented filter and search.
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  bool _searching = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    setState(() => _searching = false);
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredMatchesProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final filter = ref.watch(matchFilterProvider);
    final competition = ref.watch(selectedCompetitionProvider);
    final competitionCode = competition.code;
    // Only jump to "today" on the unfiltered All view; other tabs/search start
    // at the top where their results naturally read.
    final autoScrollToToday = filter == MatchFilter.all && query.isEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: _searching ? 8 : 16,
        flexibleSpace: const HeaderGradient(),
        title: _searching ? _searchField(context) : const CompetitionAppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Close search' : 'Search teams',
            onPressed: _searching ? _closeSearch : _openSearch,
          ),
          const SizedBox(width: 4),
        ],
        // Hide the status filter while searching (search spans all matches).
        bottom: _searching
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(52),
                child: SegmentedFilter(),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: filtered.when(
          loading: () => const _MatchesSkeleton(),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(matchesProvider),
          ),
          data: (matches) => _MatchList(
            // A fresh key per view re-applies the initial scroll position when
            // the competition/filter/search changes (but not on refresh).
            key: ValueKey('$competitionCode|${filter.name}|$query'),
            matches: matches,
            autoScrollToToday: autoScrollToToday,
            emptyIcon: _emptyIcon(query, filter),
            emptyMessage: _emptyMessage(query, filter, competition.shortName),
          ),
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.titleMedium,
      cursorColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        hintText: 'Search team (e.g. Brazil)…',
        border: InputBorder.none,
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
    );
  }

  Future<void> _refresh() async {
    await ref.read(matchesProvider.notifier).refresh();
    final err = ref.read(matchesProvider).value?.refreshError;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

/// Empty-state copy tailored to why the list is empty.
String _emptyMessage(String query, MatchFilter filter, String competitionName) {
  if (query.isNotEmpty) return 'No matches found for “$query”.';
  return switch (filter) {
    MatchFilter.favourites =>
      'No followed teams in this competition.\nOpen a match and tap ☆ to follow a team.',
    // An empty "All" view means the whole competition has no fixtures — almost
    // always because they haven't been published yet (e.g. World Cup 2026).
    MatchFilter.all =>
      'Fixtures for $competitionName haven’t been published yet.\nCheck back closer to the tournament.',
    MatchFilter.upcoming => 'No upcoming fixtures right now.',
    MatchFilter.results => 'No results yet.',
    MatchFilter.live => 'No live matches right now.',
  };
}

IconData _emptyIcon(String query, MatchFilter filter) {
  if (query.isNotEmpty) return Icons.search_off;
  return switch (filter) {
    MatchFilter.favourites => Icons.star_outline_rounded,
    MatchFilter.all => Icons.event_busy_outlined,
    MatchFilter.live => Icons.sensors_off_outlined,
    _ => Icons.search_off,
  };
}

/// A shimmering placeholder shown while the first fixtures load.
class _MatchesSkeleton extends StatelessWidget {
  const _MatchesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 4, 6, 12),
            child: SkeletonBox(width: 160, height: 12),
          ),
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          SkeletonBox(width: 90, height: 10),
                          Spacer(),
                          SkeletonBox(width: 44, height: 16, radius: 8),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: const [
                          Expanded(
                            child: Column(
                              children: [
                                SkeletonBox(
                                    width: 40,
                                    height: 40,
                                    shape: BoxShape.circle),
                                SizedBox(height: 7),
                                SkeletonBox(width: 60, height: 10),
                              ],
                            ),
                          ),
                          SkeletonBox(width: 52, height: 26, radius: 10),
                          Expanded(
                            child: Column(
                              children: [
                                SkeletonBox(
                                    width: 40,
                                    height: 40,
                                    shape: BoxShape.circle),
                                SizedBox(height: 7),
                                SkeletonBox(width: 60, height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One row in the match list: either a date heading or a match card.
sealed class _ListRow {
  const _ListRow();
}

class _HeaderRow extends _ListRow {
  const _HeaderRow(this.day, this.count);
  final String day;
  final int count;
}

class _MatchRow extends _ListRow {
  const _MatchRow(this.match);
  final MatchFixture match;
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    super.key,
    required this.matches,
    required this.emptyMessage,
    this.emptyIcon = Icons.search_off,
    this.autoScrollToToday = false,
  });

  final List<MatchFixture> matches;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool autoScrollToToday;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 110),
          Icon(emptyIcon,
              size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      );
    }

    // matches arrive sorted ascending by date. Count per day for the headers.
    final counts = <String, int>{};
    for (final m in matches) {
      final key = DateFormat('EEEE, d MMMM').format(m.utcDate);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    // Flatten into a row list (header, then that day's matches), remembering the
    // index of the first row on/after today so we can open there.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = <_ListRow>[];
    int? todayIndex;
    String? currentDay;
    for (final m in matches) {
      final day = DateFormat('EEEE, d MMMM').format(m.utcDate);
      if (day != currentDay) {
        currentDay = day;
        rows.add(_HeaderRow(day, counts[day] ?? 1));
        final dayDate = DateTime(m.utcDate.year, m.utcDate.month, m.utcDate.day);
        if (todayIndex == null && !dayDate.isBefore(today)) {
          todayIndex = rows.length - 1; // pin this date header to the top
        }
      }
      rows.add(_MatchRow(m));
    }
    // Everything is in the past (e.g. a finished competition) → open at the end
    // so the most recent matches are visible.
    todayIndex ??= rows.length - 1;

    final initialIndex = autoScrollToToday ? todayIndex : 0;

    return ScrollablePositionedList.builder(
      itemCount: rows.length,
      initialScrollIndex: initialIndex,
      // Leave a little breathing room above the pinned date header.
      initialAlignment: 0.02,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is _HeaderRow) {
          return _DayHeader(day: row.day, count: row.count);
        }
        final m = (row as _MatchRow).match;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: MatchCard(
            match: m,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchDetailScreen(match: m),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A date heading separating one matchday's fixtures from the next.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});

  final String day;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            day.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'match' : 'matches'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Could not load matches.\n$message',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
