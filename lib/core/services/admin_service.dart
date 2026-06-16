import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  try {
    final response = await Supabase.instance.client
        .from('admin_users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    return response != null;
  } catch (e) {
    return false;
  }
});

Future<void> performLogout() async {
  await Supabase.instance.client.auth.signOut();
}
