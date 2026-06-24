import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../features/add/screens/add_content_screen.dart';
import '../../features/ai_bot/screens/ai_bot_screen.dart';
import '../../features/feed/screens/main_swipe_feed_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'app_bottom_nav.dart';

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
        // AppTab order must match the children order below.
        index: _currentTab.index,
        children: [
          HomeScreen(
            onOpenLessons: () => setState(() => _currentTab = AppTab.lessons),
            onOpenProfileTab: () => setState(() => _currentTab = AppTab.profile),
          ),
          // AppTab.lessons
          MainSwipeFeedScreen(isTabActive: _currentTab == AppTab.lessons),
          // AppTab.add (center FAB)
          const AddContentScreen(),
          // AppTab.aiBot
          const AiBotScreen(),
          // AppTab.profile
          const ProfileScreen(),
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
