import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/football_loader.dart';
import '../../../core/widgets/section_header.dart';
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: _searching ? 8 : 16,
        title: _searching ? _searchField(context) : const BrandTitle(),
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
          loading: () => const AppLoader(message: 'Loading fixtures…'),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(matchesProvider),
          ),
          data: (matches) => _MatchList(
            matches: matches,
            emptyMessage: query.isNotEmpty
                ? 'No matches found for “$query”.'
                : 'No matches here yet.',
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

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches, required this.emptyMessage});

  final List<MatchFixture> matches;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 110),
          Icon(Icons.search_off,
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

    // Group matches by calendar day for readable date headers.
    final groups = <String, List<MatchFixture>>{};
    for (final m in matches) {
      final key = DateFormat('EEEE, d MMMM').format(m.utcDate);
      groups.putIfAbsent(key, () => []).add(m);
    }

    final children = <Widget>[];
    groups.forEach((day, dayMatches) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        child: Text(
          day,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ));
      for (final m in dayMatches) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: MatchCard(
            match: m,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchDetailScreen(match: m),
              ),
            ),
          ),
        ));
      }
    });
    children.add(const SizedBox(height: 24));

    return ListView(children: children);
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
