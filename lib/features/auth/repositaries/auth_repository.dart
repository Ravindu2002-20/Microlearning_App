import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Check if a cached user session exists on the device (Persistence)
  User? get currentSessionUser => _supabase.auth.currentUser;

  /// Listen to changes in authentication state (e.g., sudden signouts)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// First time registration using Email and Password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  /// Subsequent sign-ins if the user explicitly logged out
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Explicitly destroy session cache and force password entry next run
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}