import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../learning/repositories/learning_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingSave = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _emailCtrl.text = user.email ?? '';

      final profile = await LearningRepository(Supabase.instance.client)
          .fetchUserProfile(userUuid: user.id);

      final fullName = (profile?['full_name'] as String?)?.trim();
      if (fullName != null) {
        _fullNameCtrl.text = fullName;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loadingSave) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    setState(() {
      _loadingSave = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are signed out.')),
        );
        return;
      }

      final newFullName = _fullNameCtrl.text.trim();
      final newEmail = _emailCtrl.text.trim();

      // 1) Update full name in profiles table.
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': newFullName,
      });

      // 2) Update email via Supabase auth.
      // Note: Supabase may require email verification depending on settings.
      if (newEmail.isNotEmpty && newEmail != (user.email ?? '')) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: newEmail),
        );
      }

      // 3) Password reset (only when current password is correct).
      final currentPassword = _currentPasswordCtrl.text;
      final newPassword = _newPasswordCtrl.text;

      final wantsPasswordChange = currentPassword.isNotEmpty || newPassword.isNotEmpty;
      if (wantsPasswordChange) {
        if (currentPassword.isEmpty || newPassword.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter current and new password.')),
          );
          return;
        }

        // Re-authenticate using current password.
        // If this throws, the current password is wrong.
        await Supabase.instance.client.auth.signInWithPassword(
          email: newEmail.isNotEmpty ? newEmail : (user.email ?? ''),
          password: currentPassword,
        );

        // Update password.
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingSave = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text('Edit Profile'),
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                    vertical: AppDimensions.spacingLg,
                  ),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.surfaceDark,
                        child: const Icon(Icons.person_outline_rounded, size: 38),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),

                    // Full name
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter full name'
                          : null,
                    ),

                    const SizedBox(height: AppDimensions.spacingMd),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Enter email';
                        if (!s.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.spacingXxl),

                    // Password reset section
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingLg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
                        border: Border.all(
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Change password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _currentPasswordCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Current password',
                              filled: true,
                              fillColor: AppColors.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'New password',
                              filled: true,
                              fillColor: AppColors.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              final wants = _currentPasswordCtrl.text.isNotEmpty || (v?.isNotEmpty ?? false);
                              if (!wants) return null; // optional section
                              final s = v ?? '';
                              if (s.isEmpty) return 'Enter new password';
                              if (s.length < 6) return 'Min 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Password will update only if your current password is correct.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacingXxl),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loadingSave ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                        ),
                        child: _loadingSave
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}


