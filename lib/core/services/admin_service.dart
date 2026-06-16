import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  final userId = user?.id;
  if (userId == null) {
    return false;
  }

  try {
    final res = await Supabase.instance.client
        .from('admin_users')
        .select('granted_at')
        .eq('id', userId)
        .maybeSingle();

    // res == null => user is not an admin
    // res != null => user is an admin
    return res != null;
  } catch (e) {
    return false;
  }
});


Future<void> performLogout() async {
  await Supabase.instance.client.auth.signOut();
}
