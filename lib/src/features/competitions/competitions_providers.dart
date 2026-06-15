import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/competition.dart';

/// Persists the user's chosen *default* competition across launches.
class _CompetitionPrefs {
  static const _key = 'default_competition_code';

  Future<String?> readCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (e) {
      debugPrint('CompetitionPrefs.read skipped: $e');
      return null;
    }
  }

  Future<void> writeCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (e) {
      debugPrint('CompetitionPrefs.write skipped: $e');
    }
  }
}

/// The user's preferred *default* competition — the one the app opens to on
/// every launch. Defaults to [Competition.fallback] until a saved choice is
/// restored, and is updated explicitly via "set as default".
class DefaultCompetitionNotifier extends Notifier<Competition> {
  final _prefs = _CompetitionPrefs();

  @override
  Competition build() {
    _restore();
    return Competition.fallback;
  }

  Future<void> _restore() async {
    final code = await _prefs.readCode();
    if (code == null) return;
    final saved = Competition.byCode(code);
    // Only apply if the user hasn't already changed the default this session.
    if (saved != null && state.code == Competition.fallback.code) {
      state = saved;
    }
  }

  /// Marks [competition] as the default and persists it.
  Future<void> setDefault(Competition competition) async {
    state = competition;
    await _prefs.writeCode(competition.code);
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
