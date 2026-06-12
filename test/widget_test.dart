// Basic smoke test for KickOff: the app builds and shows its title without
// touching the network or platform plugins.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kickoff/src/app.dart';
import 'package:kickoff/src/features/matches/providers.dart';

/// A matches notifier that returns fixed data, so the test stays hermetic.
class _FakeMatchesNotifier extends MatchesNotifier {
  @override
  Future<MatchesData> build() async =>
      MatchesData(matches: const [], fetchedAt: DateTime.now());
}

void main() {
  testWidgets('App builds and shows the KickOff title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [matchesProvider.overrideWith(_FakeMatchesNotifier.new)],
        child: const KickOffApp(),
      ),
    );
    await tester.pump();

    expect(find.text('KickOff'), findsOneWidget);
  });
}
