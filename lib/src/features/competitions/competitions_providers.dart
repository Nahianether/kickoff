import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/competition.dart';

/// Remembers the user's last-selected competition across launches.
class _CompetitionPrefs {
  static const _key = 'selected_competition_code';

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

/// Holds the currently selected competition. Defaults to [Competition.fallback]
/// and restores the persisted choice asynchronously on launch.
class SelectedCompetitionNotifier extends Notifier<Competition> {
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
    // Only override the default if nothing has been selected yet this session.
    if (saved != null && state.code == Competition.fallback.code) {
      state = saved;
    }
  }

  Future<void> select(Competition competition) async {
    if (competition.code == state.code) return;
    state = competition;
    await _prefs.writeCode(competition.code);
  }
}

final selectedCompetitionProvider =
    NotifierProvider<SelectedCompetitionNotifier, Competition>(
  SelectedCompetitionNotifier.new,
);
