import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/competition.dart';

const _kDefaultCompetitionKey = 'default_competition_code';

/// Reads the persisted default competition. Called once in `main()` *before*
/// the app starts so it opens directly on the user's default rather than
/// flickering through the fallback (which would briefly load the wrong league).
Future<Competition> loadDefaultCompetition() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kDefaultCompetitionKey);
    if (code != null) {
      return Competition.byCode(code) ?? Competition.fallback;
    }
  } catch (e) {
    debugPrint('loadDefaultCompetition skipped: $e');
  }
  return Competition.fallback;
}

/// The default competition resolved at boot. Overridden in `main()` with the
/// persisted value via [loadDefaultCompetition]; the fallback here is only used
/// if no override is supplied (e.g. tests).
final bootstrapCompetitionProvider =
    Provider<Competition>((ref) => Competition.fallback);

/// Persists the user's chosen default competition.
Future<void> _saveDefaultCompetition(String code) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultCompetitionKey, code);
  } catch (e) {
    debugPrint('saveDefaultCompetition skipped: $e');
  }
}

/// The user's preferred *default* competition — the one the app opens to on
/// every launch. Seeded synchronously from [bootstrapCompetitionProvider] so
/// there is no async flip on startup, and updated via "set as default".
class DefaultCompetitionNotifier extends Notifier<Competition> {
  @override
  Competition build() => ref.read(bootstrapCompetitionProvider);

  /// Marks [competition] as the default and persists it.
  Future<void> setDefault(Competition competition) async {
    state = competition;
    await _saveDefaultCompetition(competition.code);
  }
}

final defaultCompetitionProvider =
    NotifierProvider<DefaultCompetitionNotifier, Competition>(
  DefaultCompetitionNotifier.new,
);

/// The competition currently being viewed. It starts at (and follows) the
/// default, but the user can browse other competitions for the session without
/// changing their default. Selecting via the Leagues tab updates this; the next
/// launch returns to the default.
class SelectedCompetitionNotifier extends Notifier<Competition> {
  @override
  Competition build() {
    // Mirror the default on launch, and whenever the default itself changes
    // (e.g. the user just set a new default, so jump to viewing it).
    return ref.watch(defaultCompetitionProvider);
  }

  /// Views [competition] for this session without changing the saved default.
  void select(Competition competition) => state = competition;
}

final selectedCompetitionProvider =
    NotifierProvider<SelectedCompetitionNotifier, Competition>(
  SelectedCompetitionNotifier.new,
);
