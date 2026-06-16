import 'package:flutter/material.dart';
import '../constants/constants.dart';

enum AppTab {
  home(Icons.home_outlined, 'Home'),
  lessons(Icons.menu_book_outlined, 'Lessons'),
  add(Icons.add_rounded, ''),
  aiBot(Icons.auto_awesome_outlined, 'AI Bot'),
  profile(Icons.person_outline, 'Profile');

  const AppTab(this.icon, this.label);
  final IconData icon;
  final String label;
}

class AppBottomNav extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final selectedColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final unselectedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.navHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background row for all nav items
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        tab: AppTab.home,
                        isSelected: currentTab == AppTab.home,
                        selectedColor: selectedColor,
                        unselectedColor: unselectedColor,
                        onTap: () => onTabSelected(AppTab.home),
                      ),
                      _NavItem(
                        tab: AppTab.lessons,
                        isSelected: currentTab == AppTab.lessons,
                        selectedColor: selectedColor,
                        unselectedColor: unselectedColor,
                        onTap: () => onTabSelected(AppTab.lessons),
                      ),
                      // Spacer for center button slot
                      SizedBox(width: AppDimensions.centerButtonSize + 8),
                      _NavItem(
                        tab: AppTab.aiBot,
                        isSelected: currentTab == AppTab.aiBot,
                        selectedColor: selectedColor,
                        unselectedColor: unselectedColor,
                        onTap: () => onTabSelected(AppTab.aiBot),
                      ),
                      _NavItem(
                        tab: AppTab.profile,
                        isSelected: currentTab == AppTab.profile,
                        selectedColor: selectedColor,
                        unselectedColor: unselectedColor,
                        onTap: () => onTabSelected(AppTab.profile),
                      ),
                    ],
                  ),
                ),
              ),
              // Center button floats above via Stack, not clipped
              Positioned(
                top: -16,
                left: 0,
                right: 0,
                child: Center(
                  child: _CenterAddButton(
                    isSelected: currentTab == AppTab.add,
                    onTap: () => onTabSelected(AppTab.add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual Nav Item ─────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final AppTab tab;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppDimensions.navHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                size: AppDimensions.navIconSize,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Center Add Button ───────────────────────────────────────────────────────

class _CenterAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;

  const _CenterAddButton({
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.centerButtonSize + 8,
        height: AppDimensions.centerButtonSize + 8,
        decoration: BoxDecoration(
          gradient: AppColors.centerButtonGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: AppDimensions.centerButtonIconSize,
        ),
      ),
    );
  }
}