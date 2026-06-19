import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreferencesRepository {
  final SupabaseClient _client;
  UserPreferencesRepository(this._client);

  Future<bool> isOnboardingComplete(String userId) async {
    final response = await _client
        .from('user_preferences')
        .select('onboarding_completed')
        .eq('user_id', userId)
        .maybeSingle();

    return response?['onboarding_completed'] as bool? ?? false;
  }

  Future<void> savePreferences({
    required String userId,
    required int age,
    required String educationStatus,
    required List<String> selectedCategories,
  }) async {
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'age': age,
      'education_status': educationStatus,
      'selected_categories': selectedCategories,
      'onboarding_completed': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

