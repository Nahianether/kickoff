import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingDoneKey = 'onboarding_done';

/// Reads whether the first-run flow has been completed (called in `main` so the
/// app decides between onboarding and the home shell on the first frame).
Future<bool> loadOnboardingDone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDoneKey) ?? false;
  } catch (e) {
    debugPrint('loadOnboardingDone skipped: $e');
    return true; // on failure, skip onboarding rather than block the app
  }
}

/// Seed for [onboardingDoneProvider]; overridden in `main` with the saved value.
final bootstrapOnboardingDoneProvider = Provider<bool>((ref) => true);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(bootstrapOnboardingDoneProvider);

  /// Marks onboarding finished (or skipped) and persists it.
  Future<void> complete() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingDoneKey, true);
    } catch (e) {
      debugPrint('saveOnboardingDone skipped: $e');
    }
  }
}

final onboardingDoneProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
