Project: MicroLearn — Context-Adaptive Microlearning App (Flutter + Supabase + Riverpod)
You are assisting with a Flutter mobile app called MicroLearn. Here is the complete architecture and workflow context:

STACK

Flutter (Dart) — UI and navigation
Supabase — auth, database (PostgreSQL), realtime
Riverpod — state management
sensors_plus — accelerometer for motion detection
connectivity_plus — network strength detection
shared_preferences — onboarding persistence


FOLDER STRUCTURE
lib/
├── main.dart                          # Entry, routing (_AppRouter), LoginRegistrationScreen
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Full color palette, gradients
│   │   ├── app_dimensions.dart        # Spacing, radius, nav sizing tokens
│   │   ├── app_typography.dart        # Text styles
│   │   └── constants.dart             # Barrel export
│   ├── services/
│   │   ├── context_engine_service.dart  # Motion + network → UserContextState stream
│   │   ├── session_manager.dart         # sessionUserProvider, logoutProvider
│   │   └── onboarding_persistence.dart  # SharedPreferences onboarding flag
│   ├── theme/
│   │   └── app_theme.dart             # AppTheme.light / AppTheme.dark
│   └── widgets/
│       ├── main_app_shell.dart         # Root shell, IndexedStack, bottomNavigationBar
│       ├── app_bottom_nav.dart         # AppTab enum, AppBottomNav, _CenterAddButton
│       ├── glass_widgets.dart          # GlassChip, GlassCard, GlassButton, GradientedButton
│       ├── context_palette.dart        # ContextPalette.fromState() — colors from context
│       ├── floating_glow.dart          # FloatingGlow, AvatarGlow
│       ├── empty_state.dart            # EmptyState widget
│       ├── error_state.dart            # ErrorState widget
│       ├── shimmer_skeleton.dart       # ShimmerSkeleton, FeedSkeleton, LessonCardSkeleton, ProfileSkeleton
│       └── widgets.dart               # Barrel export
└── features/
    ├── auth/

    │   ├── repositaries/
    │   │   └── auth_repository.dart    # signUp, signIn, signOut via Supabase
    │   └── screens/
    │       └── onboarding_screen.dart  # OnboardingScreen (3-slide PageView) + AuthScreen (login/register)
    ├── home/
    │   └── screens/
    │       └── home_screen.dart        # Dashboard: greeting, streak, carousel, grid, quizzes, heatmap
    ├── feed/
    │   ├── controllers/
    │   │   └── feed_providers.dart     # contextEngineProvider, adaptiveLessonFeedProvider
    │   ├── screens/
    │   │   └── main_swipe_feed_screen.dart  # TikTok-style vertical swipe feed, quiz injection
    │   └── widgets/
    │       ├── context_status_banner.dart   # Motion/network indicator banner
    │       └── lesson_cards.dart            # TextLessonCard, QuizLessonCard, VideoLessonCard, AudioLessonCard
    ├── learning/
    │   ├── models/
    │   │   └── lesson_model.dart       # LessonModel (id, title, content, format, difficulty, network/motion flags)
    │   └── repositories/
    │       └── learning_repository.dart  # fetchAdaptiveViewportFeed, logLessonCompletion, fetchUserProfile
    ├── add/
    │   └── screens/
    │       └── add_content_screen.dart  # Creator UI: lesson form, quiz builder, context settings
    ├── ai_bot/
    │   └── screens/
    │       └── ai_bot_screen.dart       # “Nova” AI bot screen (chat UI + simulated responses)

    └── profile/
        └── screens/
            └── profile_screen.dart      # Profile header, stats, progress cards, leaderboard, settings sheet

APP FLOW
App Launch
    │
    ▼
_AppRouter (1.2s splash)
    │
    ├─ user session exists ──────────────────────────► MainAppShell
    │
    ├─ no session + onboarding NOT done ────────────► OnboardingScreen (3 slides)
    │                                                       │
    │                                                       ▼
    │                                                  AuthScreen (login/register)
    │                                                       │
    │                                                       ▼
    │                                                  MainAppShell
    │
    └─ no session + onboarding done ────────────────► AuthScreen (login/register)
                                                            │
                                                            ▼
                                                       MainAppShell
MainAppShell tabs (IndexedStack):

0 Home — HomeScreen
1 Lessons — placeholder
2 Add — AddContentScreen (center FAB)
3 AI Bot — AiBotScreen
4 Profile — ProfileScreen


SUPABASE TABLES

profiles — user profile data (id, full_name, username, bio, avatar_url, xp, streak)
lessons — lesson content (id, title, description, content, category, difficulty_level, format, min_network_strength, safe_for_motion)
user_progress — completion tracking (user_id, lesson_id, completed_at, score)

Auth: Supabase email/password via AuthRepository. After sign-in, sessionUserProvider reads Supabase.instance.client.auth.currentUser.

ADAPTIVE CONTENT ENGINE
ContextEngineService streams UserContextState:

Motion: accelerometer magnitude > 13.0 → isInMotion = true
Network: connectivity result → AppNetworkStrength (weak / medium / strong)

LearningRepository.fetchAdaptiveViewportFeed() filters lessons by:

safe_for_motion = true when user is in motion
min_network_strength matching current network level
Excludes already-completed lessons (via user_progress)
Falls back to _offlineCache on Supabase error


KEY PROVIDERS (Riverpod)

sessionUserProvider — User? from Supabase auth
hasCompletedOnboardingProvider — StateProvider<bool>, persisted via shared_preferences
contextEngineProvider — ContextEngineService instance
contextStateStreamProvider — Stream<UserContextState>
learningRepositoryProvider — LearningRepository
adaptiveLessonFeedProvider(contextState) — AsyncValue<List<LessonModel>>
chatMessagesProvider — chat message list for AI bot
isNovaGeneratingProvider — bool loading state for AI bot

AI BOT (Nova) — what it does in code
- Screen: lib/features/ai_bot/screens/ai_bot_screen.dart
- UI: a chat-style interface with (1) Nova header/avatar, (2) scrollable message list, (3) suggestion chips, (4) input bar.
- State: 
  - ChatMessageModel holds {sender: user|nova, text, timestamp}.
  - ChatNotifier (Riverpod StateNotifier) stores the in-memory list of messages.
- “Generation” behavior (current implementation):
  - When user sends a message, _sendMessage adds the user bubble, sets isNovaGeneratingProvider=true, waits ~1.2s (simulated latency), then returns a response built from keyword matching in the text.
  - Supported intents by keyword: quiz/test, summarize/summary, flashcard/card, greetings, explain/what is/how, neural/network, and a default fallback.
- Message rendering:
  - _ChatMessageWidget draws different bubble styles for user vs Nova.
  - _RichMessageContent supports:
    - Bullet lists (lines starting with • or -)
    - Bold markers using **bold** (renders via RegExp in _buildFormattedText)
    - Simple multiple-choice quiz formatting (lines containing A) B) C) D))
- Typing indicator:
  - While isNovaGeneratingProvider=true, the list shows _TypingIndicator at the bottom.

authRepositoryProvider — AuthRepository
logoutProvider — calls Supabase signOut


KNOWN ISSUES / DECISIONS ALREADY MADE

Nav bar uses a custom Container (not Flutter's BottomNavigationBar). Fix for double safe-area inset: remove MediaQuery.padding.bottom from Container height; wrap content in SizedBox(height: navHeight) inside SafeArea(top: false).
_AppRouter else-branch (returning user, no session) now routes to AuthScreen instead of OnboardingScreen.
AuthScreen._submit() must call real AuthRepository methods — not a simulated delay.
hasCompletedOnboardingProvider is persisted via shared_preferences (not in-memory only).
StateProvider updates use .notifier).update((_) => true) — not .state =.
shared_preferences must be in pubspec.yaml.


DESIGN SYSTEM

Dark mode only (ThemeMode.dark)

Colors: AppColors.* — primary (#7B61FF), secondary (#00E5FF), background dark (#0A0A0F), surface dark (#13131A)
Gradients: primaryGradient, aiGradient, centerButtonGradient, streakGradient, quizGradient
Spacing/radius tokens: all from AppDimensions.*
Typography: all from AppTypography.*
Glassmorphism components: GlassCard, GlassChip, GlassButton


CONVENTIONS

All screens are ConsumerStatefulWidget or ConsumerWidget
Repository classes take SupabaseClient in constructor
Feature folders own their own models, repositories, controllers, screens, and widgets
Barrel exports used at core/widgets/widgets.dart and core/constants/constants.dart
No BottomNavigationBar widget — nav is fully custom via AppBottomNav
AddContentScreen publish is currently simulated (snackbar after delay) — not yet wired to Supabase insert