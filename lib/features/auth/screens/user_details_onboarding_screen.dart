import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/main_app_shell.dart';
import '../../../main.dart';





class UserDetailsOnboardingScreen extends ConsumerStatefulWidget {
  const UserDetailsOnboardingScreen({super.key});

  @override
  ConsumerState<UserDetailsOnboardingScreen> createState() =>
      _UserDetailsOnboardingScreenState();
}

class _UserDetailsOnboardingScreenState
    extends ConsumerState<UserDetailsOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageCtrl = TextEditingController();
  String _educationStatus = 'school';
  final List<String> _selectedCategories = [];

  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _ageCtrl.dispose();
    super.dispose();
  }

  static const _categories = [
    'Science',
    'Math',
    'History',
    'Technology',
    'Language',
    'Art',
    'Health',
    'Business',
  ];

  static const _educationStatuses = [
    'school',
    'undergraduate',
    'working_professional',
    'other',
  ];

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      setState(() => _errorMsg = 'Session expired. Please log in again.');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser!.id;
    if (_selectedCategories.isEmpty) {
      setState(() => _errorMsg = 'Please select at least one category.');
      return;
    }

    final age = int.parse(_ageCtrl.text.trim());

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await ref.read(userPreferencesRepositoryProvider).savePreferences(
            userId: userId,
            age: age,
            educationStatus: _educationStatus,
            selectedCategories: List.of(_selectedCategories),
          );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainAppShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return PopScope(
      canPop: false,
      child: Scaffold(

        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Personalize your learning',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A quick setup so we can recommend the right lessons.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _SectionLabel('Age', textPrimary),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide(
                            color: AppColors.textSecondaryDark.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                        labelText: 'Your age',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Age is required';
                        final n = int.tryParse(s);
                        if (n == null) return 'Enter a valid number';
                        if (n < 5 || n > 120) return 'Age must be between 5 and 120';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),
                    _SectionLabel('Education status', textPrimary),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.12),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _educationStatus,
                          isExpanded: true,
                          dropdownColor: surfaceColor,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          items: _educationStatuses
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e
                                        .split('_')
                                        .map((p) =>
                                            p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
                                        .join(' ')),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _educationStatus = v);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _SectionLabel('Learning categories', textPrimary),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((c) {
                        final selected = _selectedCategories.contains(c);
                        return _CategoryChip(
                          label: c,
                          selected: selected,
                          selectedColor: primary,
                          unselectedColor: surfaceColor,
                          textSelectedColor: Colors.white,
                          textUnselectedColor: textSecondary,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedCategories.remove(c);
                              } else {
                                _selectedCategories.add(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    if (_errorMsg != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border:
                              Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color textSelectedColor;
  final Color textUnselectedColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.textSelectedColor,
    required this.textUnselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? selectedColor : AppColors.primaryDark.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? textSelectedColor : textUnselectedColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

