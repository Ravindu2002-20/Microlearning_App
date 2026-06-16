import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Session Manager — Persistent session via Supabase local cache
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the current Supabase User if a session exists (cached locally).
/// On app startup, Supabase restores the session from local storage automatically.
/// This provider reads that restored state.
final sessionUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Global logout action
final logoutProvider = Provider<void Function()>((ref) {
  return () async {
    await Supabase.instance.client.auth.signOut();
    // Invalidate all cached states
    ref.invalidate(sessionUserProvider);
  };
});