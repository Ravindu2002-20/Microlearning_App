import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/constants.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/add/screens/add_content_screen.dart';
import '../../features/ai_bot/screens/ai_bot_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'app_bottom_nav.dart';
import 'empty_state.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MainAppShell — Bottom Navigation Container
// ═════════════════════════════════════════════════════════════════════════════

class MainAppShell extends ConsumerStatefulWidget {
  const MainAppShell({super.key});

  @override
  ConsumerState<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends ConsumerState<MainAppShell> {
  AppTab _currentTab = AppTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: const [
          HomeScreen(),           // ← dashboard
          _LessonsPlaceholderTab(),
          AddContentScreen(),
          AiBotScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          setState(() => _currentTab = tab);
        },
      ),
    );
  }
}

// ─── Placeholder Tab ───────────────────────────────────────────────────────

class _LessonsPlaceholderTab extends StatelessWidget {
  const _LessonsPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Lessons')),
      body: EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Your Lessons',
        subtitle: 'Personalized learning paths will appear here.',
        actionLabel: 'Explore',
        accentColor: AppColors.primaryDark,
      ),
    );
  }
}