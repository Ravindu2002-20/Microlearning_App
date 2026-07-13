import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../learning/repositories/learning_repository.dart';

class LearningPreferencesScreen extends StatefulWidget {
  const LearningPreferencesScreen({super.key});

  @override
  State<LearningPreferencesScreen> createState() => _LearningPreferencesScreenState();
}

class _LearningPreferencesScreenState extends State<LearningPreferencesScreen> {
  final _repo = LearningRepository(Supabase.instance.client);
  bool _loading = true;
  bool _saving = false;

  List<String> _availableCategories = const [];
  Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final result = await _repo.fetchLearningPreferences(userUuid: user.id);
      setState(() {
        _availableCategories = result.availableCategories;
        _selected = result.selectedCategories.toSet();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String category) async {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repo.updateLearningPreferences(
        userUuid: user.id,
        selectedCategories: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(brightness),
        foregroundColor: AppColors.textPrimaryFor(brightness),
        title: const Text('Learning Preferences'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _availableCategories.isEmpty
                ? const Center(child: Text('No categories available'))
                : Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select the categories you want to see more often.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryFor(brightness),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            itemCount: _availableCategories.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.4,
                            ),
                            itemBuilder: (context, index) {
                              final c = _availableCategories[index];
                              final selected = _selected.contains(c);

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _toggle(c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primaryFor(brightness)
                                            .withValues(alpha: 0.14)
                                        : AppColors.surfaceFor(brightness),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primaryFor(brightness)
                                              .withValues(alpha: 0.35)
                                          : AppColors.textSecondaryFor(brightness)
                                              .withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.add_circle_outline_rounded,
                                        size: 18,
                                        color: selected
                                            ? AppColors.primaryFor(brightness)
                                            : AppColors.textSecondaryFor(brightness),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: selected
                                                ? AppColors.primaryFor(brightness)
                                                : AppColors.textPrimaryFor(brightness),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryFor(brightness),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusFull),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : const Text('Save Preferences'),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

