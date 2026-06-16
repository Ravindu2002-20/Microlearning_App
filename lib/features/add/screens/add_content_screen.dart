import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddContentScreen — Creator upload screen (YouTube Studio meets modern mobile)
// ─────────────────────────────────────────────────────────────────────────────

class AddContentScreen extends ConsumerStatefulWidget {
  const AddContentScreen({super.key});

  @override
  ConsumerState<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends ConsumerState<AddContentScreen> {
  // ── Form Controllers ────────────────────────────────────────────────────

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── Selectors ───────────────────────────────────────────────────────────

  String _selectedCategory = 'Science';
  String _selectedDifficulty = 'Easy';
  String _selectedFormat = 'Video';
  String _selectedNetwork = 'Weak';
  bool _safeForMotion = true;

  // ── Quiz Builder ────────────────────────────────────────────────────────

  bool _quizExpanded = false;
  final List<_QuizQuestion> _quizQuestions = [];
  final _questionCtrl = TextEditingController();
  final _optionACtrl = TextEditingController();
  final _optionBCtrl = TextEditingController();
  final _optionCCtrl = TextEditingController();
  final _optionDCtrl = TextEditingController();
  int _correctAnswer = 0;

  // ── Media Upload State ──────────────────────────────────────────────────

  bool _hasVideo = false;
  bool _hasThumbnail = false;
  bool _hasAudio = false;

  // ── Publish State ───────────────────────────────────────────────────────

  bool _isPublishing = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _questionCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _addQuizQuestion() {
    if (_questionCtrl.text.trim().isEmpty) return;
    if (_optionACtrl.text.trim().isEmpty ||
        _optionBCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _quizQuestions.add(_QuizQuestion(
        question: _questionCtrl.text.trim(),
        options: [
          _optionACtrl.text.trim(),
          _optionBCtrl.text.trim(),
          _optionCCtrl.text.trim(),
          _optionDCtrl.text.trim(),
        ],
        correctIndex: _correctAnswer,
      ));

      // Reset fields
      _questionCtrl.clear();
      _optionACtrl.clear();
      _optionBCtrl.clear();
      _optionCCtrl.clear();
      _optionDCtrl.clear();
      _correctAnswer = 0;
    });
  }

  void _removeQuizQuestion(int index) {
    setState(() {
      _quizQuestions.removeAt(index);
    });
  }

  void _publish() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isPublishing = true);

    // Simulate upload
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isPublishing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Lesson published! +50 XP earned'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Create'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable Form ────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingLg,
                  AppDimensions.spacingSm,
                  AppDimensions.spacingLg,
                  AppDimensions.spacingXxl,
                ),
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Text(
                    'Share Your Knowledge',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      height: 1.05,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'Help learners around the world.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Upload Area ────────────────────────────────────────
                  _UploadArea(
                    hasVideo: _hasVideo,
                    hasThumbnail: _hasThumbnail,
                    hasAudio: _hasAudio,
                    surfaceColor: surfaceColor,
                    textSecondary: textSecondary,
                    primary: primary,
                    onUploadVideo: () {
                      setState(() => _hasVideo = !_hasVideo);
                    },
                    onUploadThumbnail: () {
                      setState(() => _hasThumbnail = !_hasThumbnail);
                    },
                    onUploadAudio: () {
                      setState(() => _hasAudio = !_hasAudio);
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Lesson Title ────────────────────────────────────────
                  _SectionLabel(label: 'Lesson Title'),
                  const SizedBox(height: AppDimensions.spacingSm),
                  TextFormField(
                    controller: _titleCtrl,
                    style: TextStyle(color: textPrimary, fontSize: 16),
                    decoration: _inputDecoration(
                      hint: 'e.g. Introduction to Quantum Physics',
                      surfaceColor: surfaceColor,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Category Selector ───────────────────────────────────
                  _SectionLabel(label: 'Category'),
                  const SizedBox(height: AppDimensions.spacingSm),
                  _SelectorRow(
                    options: ['Science', 'Technology', 'Math', 'Business', 'Languages'],
                    selected: _selectedCategory,
                    onSelect: (v) => setState(() => _selectedCategory = v),
                    surfaceColor: surfaceColor,
                    primary: primary,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Difficulty Selector ─────────────────────────────────
                  _SectionLabel(label: 'Difficulty'),
                  const SizedBox(height: AppDimensions.spacingSm),
                  _SelectorRow(
                    options: ['Easy', 'Medium', 'Hard'],
                    selected: _selectedDifficulty,
                    onSelect: (v) => setState(() => _selectedDifficulty = v),
                    surfaceColor: surfaceColor,
                    primary: primary,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Format Selector ─────────────────────────────────────
                  _SectionLabel(label: 'Format'),
                  const SizedBox(height: AppDimensions.spacingSm),
                  _SelectorRow(
                    options: ['Video', 'Quiz', 'Text', 'Audio'],
                    selected: _selectedFormat,
                    onSelect: (v) => setState(() => _selectedFormat = v),
                    surfaceColor: surfaceColor,
                    primary: primary,
                    textPrimary: textPrimary,
                    icons: {
                      'Video': Icons.videocam_outlined,
                      'Quiz': Icons.quiz_outlined,
                      'Text': Icons.text_fields_rounded,
                      'Audio': Icons.mic_outlined,
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Description ─────────────────────────────────────────
                  _SectionLabel(label: 'Description'),
                  const SizedBox(height: AppDimensions.spacingSm),
                  TextFormField(
                    controller: _descriptionCtrl,
                    style: TextStyle(color: textPrimary, fontSize: 16),
                    maxLines: 4,
                    decoration: _inputDecoration(
                      hint: 'Describe what learners will gain...',
                      surfaceColor: surfaceColor,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  // ── Quiz Builder (expandable) ──────────────────────────
                  if (_selectedFormat == 'Quiz') ...[
                    _QuizBuilderSection(
                      expanded: _quizExpanded,
                      questions: _quizQuestions,
                      questionCtrl: _questionCtrl,
                      optionACtrl: _optionACtrl,
                      optionBCtrl: _optionBCtrl,
                      optionCCtrl: _optionCCtrl,
                      optionDCtrl: _optionDCtrl,
                      correctAnswer: _correctAnswer,
                      onToggle: () =>
                          setState(() => _quizExpanded = !_quizExpanded),
                      onAddQuestion: _addQuizQuestion,
                      onRemoveQuestion: _removeQuizQuestion,
                      onCorrectAnswerChanged: (v) =>
                          setState(() => _correctAnswer = v),
                      surfaceColor: surfaceColor,
                      primary: primary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                  ],

                  // ── Context Settings ────────────────────────────────────
                  _ContextSettingsSection(
                    selectedNetwork: _selectedNetwork,
                    safeForMotion: _safeForMotion,
                    onNetworkChanged: (v) =>
                        setState(() => _selectedNetwork = v),
                    onSafeForMotionChanged: (v) =>
                        setState(() => _safeForMotion = v),
                    surfaceColor: surfaceColor,
                    primary: primary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: AppDimensions.spacingBig),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom Publish Bar ─────────────────────────────────
          _PublishBar(
            isPublishing: _isPublishing,
            primary: primary,
            surfaceColor: surfaceColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onPublish: _publish,
          ),
        ],
      ),
    );
  }

  // ── Shared Input Decoration ──────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required Color surfaceColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight)
            .withValues(alpha: 0.6),
        fontSize: 15,
      ),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight)
              .withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Section Label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Upload Area ────────────────────────────────────────────────────────────

class _UploadArea extends StatelessWidget {
  final bool hasVideo;
  final bool hasThumbnail;
  final bool hasAudio;
  final Color surfaceColor;
  final Color textSecondary;
  final Color primary;
  final VoidCallback onUploadVideo;
  final VoidCallback onUploadThumbnail;
  final VoidCallback onUploadAudio;

  const _UploadArea({
    required this.hasVideo,
    required this.hasThumbnail,
    required this.hasAudio,
    required this.surfaceColor,
    required this.textSecondary,
    required this.primary,
    required this.onUploadVideo,
    required this.onUploadThumbnail,
    required this.onUploadAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Large Dashed Upload Area ──
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
            border: Border.all(
              color: primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: primary.withValues(alpha: 0.4),
              radius: AppDimensions.cardRadiusMd,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.centerButtonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    'Tap to upload your lesson content',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'Video, thumbnail, or audio',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),

        // ── Upload Options Row ──
        Row(
          children: [
            _UploadOption(
              icon: Icons.videocam_rounded,
              label: 'Video',
              uploaded: hasVideo,
              primary: primary,
              onTap: onUploadVideo,
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            _UploadOption(
              icon: Icons.image_outlined,
              label: 'Thumbnail',
              uploaded: hasThumbnail,
              primary: primary,
              onTap: onUploadThumbnail,
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            _UploadOption(
              icon: Icons.mic_outlined,
              label: 'Audio',
              uploaded: hasAudio,
              primary: primary,
              onTap: onUploadAudio,
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool uploaded;
  final Color primary;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.uploaded,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingMd,
          ),
          decoration: BoxDecoration(
            color: uploaded
                ? primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: uploaded
                  ? primary.withValues(alpha: 0.3)
                  : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)
                      .withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                uploaded ? Icons.check_circle_rounded : icon,
                color: uploaded ? AppColors.success : primary,
                size: 24,
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                uploaded ? 'Added' : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: uploaded ? AppColors.success : primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ──────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    // Draw dashed path
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();
    const dashLength = 8.0;
    const gapLength = 6.0;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Selector Row (chips) ───────────────────────────────────────────────────

class _SelectorRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final Color surfaceColor;
  final Color primary;
  final Color textPrimary;
  final Map<String, IconData>? icons;

  const _SelectorRow({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.surfaceColor,
    required this.primary,
    required this.textPrimary,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppDimensions.spacingSm,
      runSpacing: AppDimensions.spacingSm,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingLg,
              vertical: AppDimensions.spacingSm + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.15)
                  : surfaceColor,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: isSelected
                    ? primary.withValues(alpha: 0.5)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                        .withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icons != null && icons!.containsKey(option)) ...[
                  Icon(
                    icons![option],
                    size: 16,
                    color: isSelected ? primary : textPrimary,
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                ],
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? primary : textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Quiz Builder Section ───────────────────────────────────────────────────

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class _QuizBuilderSection extends StatelessWidget {
  final bool expanded;
  final List<_QuizQuestion> questions;
  final TextEditingController questionCtrl;
  final TextEditingController optionACtrl;
  final TextEditingController optionBCtrl;
  final TextEditingController optionCCtrl;
  final TextEditingController optionDCtrl;
  final int correctAnswer;
  final VoidCallback onToggle;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final void Function(int) onCorrectAnswerChanged;
  final Color surfaceColor;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const _QuizBuilderSection({
    required this.expanded,
    required this.questions,
    required this.questionCtrl,
    required this.optionACtrl,
    required this.optionBCtrl,
    required this.optionCCtrl,
    required this.optionDCtrl,
    required this.correctAnswer,
    required this.onToggle,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onCorrectAnswerChanged,
    required this.surfaceColor,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questionCount = questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Accordion Header ──
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentQuiz.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    color: AppColors.accentQuiz,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Builder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      if (questionCount > 0)
                        Text(
                          '$questionCount question${questionCount > 1 ? 's' : ''} added',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accentQuiz,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expanded Content ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacingLg),
            child: _QuizFormContent(
              questionCtrl: questionCtrl,
              optionACtrl: optionACtrl,
              optionBCtrl: optionBCtrl,
              optionCCtrl: optionCCtrl,
              optionDCtrl: optionDCtrl,
              correctAnswer: correctAnswer,
              onAddQuestion: onAddQuestion,
              onCorrectAnswerChanged: onCorrectAnswerChanged,
              surfaceColor: surfaceColor,
              primary: primary,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              questions: questions,
              onRemoveQuestion: onRemoveQuestion,
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
        ),
      ],
    );
  }
}

class _QuizFormContent extends StatelessWidget {
  final TextEditingController questionCtrl;
  final TextEditingController optionACtrl;
  final TextEditingController optionBCtrl;
  final TextEditingController optionCCtrl;
  final TextEditingController optionDCtrl;
  final int correctAnswer;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onCorrectAnswerChanged;
  final Color surfaceColor;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final List<_QuizQuestion> questions;
  final void Function(int) onRemoveQuestion;

  const _QuizFormContent({
    required this.questionCtrl,
    required this.optionACtrl,
    required this.optionBCtrl,
    required this.optionCCtrl,
    required this.optionDCtrl,
    required this.correctAnswer,
    required this.onAddQuestion,
    required this.onCorrectAnswerChanged,
    required this.surfaceColor,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.questions,
    required this.onRemoveQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Existing Questions ──
        if (questions.isNotEmpty) ...[
          ...List.generate(questions.length, (index) {
            final q = questions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.accentQuiz.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: AppColors.accentQuiz.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${index + 1}: ${q.question}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${q.options.length} options • Correct: ${String.fromCharCode(65 + q.correctIndex)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accentQuiz,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.error,
                    onPressed: () => onRemoveQuestion(index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppDimensions.spacingLg),
        ],

        // ── Question Input ──
        Text(
          'Add Question',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        TextFormField(
          controller: questionCtrl,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter your question...',
            hintStyle: TextStyle(
              color: textSecondary.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: surfaceColor,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingMd,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),

        // ── Options ──
        _OptionInput(
          label: 'A',
          controller: optionACtrl,
          surfaceColor: surfaceColor,
          textPrimary: textPrimary,
          isCorrect: correctAnswer == 0,
          onSelectCorrect: () => onCorrectAnswerChanged(0),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        _OptionInput(
          label: 'B',
          controller: optionBCtrl,
          surfaceColor: surfaceColor,
          textPrimary: textPrimary,
          isCorrect: correctAnswer == 1,
          onSelectCorrect: () => onCorrectAnswerChanged(1),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        _OptionInput(
          label: 'C',
          controller: optionCCtrl,
          surfaceColor: surfaceColor,
          textPrimary: textPrimary,
          isCorrect: correctAnswer == 2,
          onSelectCorrect: () => onCorrectAnswerChanged(2),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        _OptionInput(
          label: 'D',
          controller: optionDCtrl,
          surfaceColor: surfaceColor,
          textPrimary: textPrimary,
          isCorrect: correctAnswer == 3,
          onSelectCorrect: () => onCorrectAnswerChanged(3),
        ),
        const SizedBox(height: AppDimensions.spacingLg),

        // ── Add Question Button ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddQuestion,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Question'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentQuiz,
              side: BorderSide(
                color: AppColors.accentQuiz.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color surfaceColor;
  final Color textPrimary;
  final bool isCorrect;
  final VoidCallback onSelectCorrect;

  const _OptionInput({
    required this.label,
    required this.controller,
    required this.surfaceColor,
    required this.textPrimary,
    required this.isCorrect,
    required this.onSelectCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onSelectCorrect,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect
                  ? AppColors.accentQuiz
                  : surfaceColor,
              border: Border.all(
                color: isCorrect
                    ? AppColors.accentQuiz
                    : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                        .withValues(alpha: 0.2),
                width: isCorrect ? 0 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isCorrect ? Colors.white : textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: TextFormField(
            controller: controller,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Option $label',
              hintStyle: TextStyle(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                    .withValues(alpha: 0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Context Settings Section ───────────────────────────────────────────────

class _ContextSettingsSection extends StatefulWidget {
  final String selectedNetwork;
  final bool safeForMotion;
  final ValueChanged<String> onNetworkChanged;
  final ValueChanged<bool> onSafeForMotionChanged;
  final Color surfaceColor;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const _ContextSettingsSection({
    required this.selectedNetwork,
    required this.safeForMotion,
    required this.onNetworkChanged,
    required this.onSafeForMotionChanged,
    required this.surfaceColor,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_ContextSettingsSection> createState() =>
      _ContextSettingsSectionState();
}

class _ContextSettingsSectionState extends State<_ContextSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentWeakNetwork.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 16,
                color: AppColors.accentWeakNetwork,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Text(
              'Context Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: widget.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingLg),

        // ── Minimum Network Required ──
        Text(
          'Minimum Network Required',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        _SelectorRow(
          options: ['Weak', 'Medium', 'Strong'],
          selected: widget.selectedNetwork,
          onSelect: widget.onNetworkChanged,
          surfaceColor: widget.surfaceColor,
          primary: widget.primary,
          textPrimary: widget.textPrimary,
        ),
        const SizedBox(height: AppDimensions.spacingLg),

        // ── Safe for Motion Toggle ──
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: widget.safeForMotion
                ? AppColors.accentMotion.withValues(alpha: 0.08)
                : widget.surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: widget.safeForMotion
                  ? AppColors.accentMotion.withValues(alpha: 0.2)
                  : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)
                      .withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Walking icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentMotion.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.accentMotion,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safe for Motion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Can be consumed while walking.',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.safeForMotion,
                onChanged: widget.onSafeForMotionChanged,
                activeTrackColor: AppColors.accentMotion,
                inactiveTrackColor: (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                    .withValues(alpha: 0.15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sticky Publish Bar ──────────────────────────────────────────────────────

class _PublishBar extends StatelessWidget {
  final bool isPublishing;
  final Color primary;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onPublish;

  const _PublishBar({
    required this.isPublishing,
    required this.primary,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.bottom + AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // XP Reward badge
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingXs,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.streakGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentStreak.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: AppDimensions.spacingXs),
                Text(
                  'Contributors earn +50 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Publish Button
          GestureDetector(
            onTap: isPublishing ? null : onPublish,
            child: Container(
              width: double.infinity,
              height: AppDimensions.buttonHeightMd + 4,
              decoration: BoxDecoration(
                gradient: AppColors.centerButtonGradient,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isPublishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.publish_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: AppDimensions.spacingSm),
                          Text(
                            'Publish Lesson',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}