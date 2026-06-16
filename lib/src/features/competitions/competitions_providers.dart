import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/competition.dart';

// Kept the original key so a previously-saved league (e.g. one picked during
// onboarding) carries over as the league the app now reopens to.
const _kCompetitionKey = 'default_competition_code';

/// Reads the persisted current league before the first frame (called in
/// `main`), so the app opens directly on the league the user last viewed
/// rather than flickering through the fallback.
Future<Competition> loadSavedCompetition() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kCompetitionKey);
    if (code != null) {
      return Competition.byCode(code) ?? Competition.fallback;
    }
  } catch (e) {
    debugPrint('loadSavedCompetition skipped: $e');
  }
  return Competition.fallback;
}

/// The league resolved at boot. Overridden in `main` with the persisted value
/// via [loadSavedCompetition]; the fallback here is only used if no override is
/// supplied (e.g. tests).
final bootstrapCompetitionProvider =
    Provider<Competition>((ref) => Competition.fallback);

Future<void> _saveCompetition(String code) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompetitionKey, code);
  } catch (e) {
    debugPrint('saveCompetition skipped: $e');
  }
}

/// The league the user is currently viewing. It is **persisted**: selecting a
/// league makes it the one the app reopens to on the next launch (a simple
/// "remember where I was" model — there is no separate default to manage).
class SelectedCompetitionNotifier extends Notifier<Competition> {
  @override
  Competition build() => ref.read(bootstrapCompetitionProvider);

  /// Views [competition] and remembers it for next launch.
  void select(Competition competition) {
    if (competition.code == state.code) return;
    state = competition;
    _saveCompetition(competition.code);
  }
}

final selectedCompetitionProvider =
    NotifierProvider<SelectedCompetitionNotifier, Competition>(
  SelectedCompetitionNotifier.new,
);
