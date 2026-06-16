import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/lesson_repository.dart';
import '../../learning/repositories/learning_repository.dart';

final _myUploadsProvider =
    FutureProvider.autoDispose<List<LessonModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  final repo = LearningRepository(Supabase.instance.client);
  return repo.fetchMyUploads(user.id);
});

class AddContentScreen extends ConsumerStatefulWidget {
  const AddContentScreen({super.key});

  @override
  ConsumerState<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends ConsumerState<AddContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Create',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primaryDark,
          tabs: const [
            Tab(text: 'Upload Lesson'),
            Tab(text: 'My Uploads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadForm(
            onUploaded: () {
              ref.invalidate(_myUploadsProvider);
              _tabController.animateTo(1);
            },
          ),
          const _MyUploadsTab(),
        ],
      ),
    );
  }
}

class _UploadForm extends ConsumerStatefulWidget {
  final VoidCallback onUploaded;
  const _UploadForm({required this.onUploaded});

  @override
  ConsumerState<_UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends ConsumerState<_UploadForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _selectedVideo;
  String _category = 'Science';
  String _difficulty = 'beginner';
  String _format = 'text';
  String _minNetwork = 'weak';
  bool _safeForMotion = true;
  bool _loading = false;

  final _categories = const [
    'Science',
    'Math',
    'History',
    'Technology',
    'Language',
    'Art',
    'Health',
    'Business',
  ];
  final _difficulties = const ['beginner', 'intermediate', 'advanced'];
  final _formats = const ['text', 'quiz', 'audio', 'video'];
  final _networks = const ['weak', 'medium', 'strong'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lesson video first.')),
      );
      return;
    }

    setState(() => _loading = true);

    final lesson = LessonModel(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      category: _category,
      difficultyLevel: _difficulty,
      format: _format,
      minNetworkStrength: _minNetwork,
      safeForMotion: _safeForMotion,
      uploadedBy: user.id,
      status: 'pending',
      isPublished: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = LessonRepository(Supabase.instance.client);
    try {
      await repo.submitLesson(
        lesson: lesson,
        videoFile: File(_selectedVideo!.path),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Upload failed. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
    _titleCtrl.clear();
    _descCtrl.clear();
    _contentCtrl.clear();
    _selectedVideo = null;
    widget.onUploaded();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Lesson submitted for review! You will be notified once approved.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Lesson Details', textPrimary),
            const SizedBox(height: 12),
            _buildVideoPicker(surface, textPrimary, textSecondary),
            const SizedBox(height: 14),
            _buildField(
              controller: _titleCtrl,
              label: 'Title',
              hint: 'e.g. What is Photosynthesis?',
              surface: surface,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              maxLines: 1,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _descCtrl,
              label: 'Short Description',
              hint: 'One or two sentences about this lesson',
              surface: surface,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _contentCtrl,
              label: 'Lesson Content',
              hint: 'Write the full lesson content here...',
              surface: surface,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              maxLines: 6,
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Content must be at least 20 characters'
                  : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Classification', textPrimary),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Category',
                    value: _category,
                    items: _categories,
                    surface: surface,
                    textPrimary: textPrimary,
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Difficulty',
                    value: _difficulty,
                    items: _difficulties,
                    surface: surface,
                    textPrimary: textPrimary,
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Format',
                    value: _format,
                    items: _formats,
                    surface: surface,
                    textPrimary: textPrimary,
                    onChanged: (v) => setState(() => _format = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Min Network',
                    value: _minNetwork,
                    items: _networks,
                    surface: surface,
                    textPrimary: textPrimary,
                    onChanged: (v) => setState(() => _minNetwork = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safe for Motion',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Works while user is moving',
                          style:
                              TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _safeForMotion,
                    onChanged: (v) => setState(() => _safeForMotion = v),
                    activeThumbColor: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your lesson will be reviewed by an admin before it becomes visible to other users.',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _loading ? null : AppColors.primaryGradient,
                  color: _loading
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Center(
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
                          'Submit for Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPicker(
    Color surface,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lesson Video',
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _loading
              ? null
              : () async {
                  final video = await _picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (!mounted || video == null) return;
                  setState(() => _selectedVideo = video);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVideo == null
                            ? 'Tap to choose a video'
                            : _selectedVideo!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedVideo == null
                            ? 'MP4, MOV, and similar video files'
                            : 'Video selected',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.upload_rounded, color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textPrimary, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSecondary),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Color surface,
    required Color textPrimary,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: surface,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _MyUploadsTab extends ConsumerWidget {
  const _MyUploadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploadsAsync = ref.watch(_myUploadsProvider);

    return uploadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load uploads',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 64,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No uploads yet',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_myUploadsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              return _UploadCard(lesson: lessons[index]);
            },
          ),
        );
      },
    );
  }
}

class _UploadCard extends StatelessWidget {
  final LessonModel lesson;
  const _UploadCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final statusColor = switch (lesson.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    final statusLabel = switch (lesson.status) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lesson.description,
            style: TextStyle(color: textSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (lesson.status == 'rejected' && lesson.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${lesson.rejectionReason}',
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(lesson.category,
                  style: TextStyle(color: textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text('•',
                  style: TextStyle(color: textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text(lesson.format,
                  style: TextStyle(color: textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text('•',
                  style: TextStyle(color: textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text(
                lesson.difficultyLevel,
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
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
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}
