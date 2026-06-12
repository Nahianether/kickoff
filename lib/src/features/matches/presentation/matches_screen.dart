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

/// Home screen: World Cup fixtures & results with a segmented filter.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandTitle(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(52),
          child: SegmentedFilter(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: filtered.when(
          loading: () => const AppLoader(message: 'Loading fixtures…'),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(matchesProvider),
          ),
          data: (matches) => _MatchList(matches: matches),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    await ref.read(matchesProvider.notifier).refresh();
    final err = ref.read(matchesProvider).value?.refreshError;
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches});

  final List<MatchFixture> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              'No matches here yet.',
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
