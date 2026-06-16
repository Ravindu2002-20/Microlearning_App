import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingCompleteKey = 'onboarding_complete';

final onboardingPersistenceProvider = Provider<OnboardingPersistence>((ref) {
  return OnboardingPersistence();
});

class OnboardingPersistence {
  Future<bool> readCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompleteKey) ?? false;
  }

  Future<void> writeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleteKey, true);
  }
}

