import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/constants.dart';
import '../../features/admin/screens/admin_profile_screen.dart';
import '../../features/admin/screens/admin_review_screen.dart';

enum AdminTab { review, profile }

final adminTabProvider = StateProvider<AdminTab>((ref) => AdminTab.review);

class AdminAppShell extends ConsumerWidget {
  const AdminAppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(adminTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final selectedColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final unselectedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: currentTab.index,
        children: const [
          AdminReviewScreen(),
          AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
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
            child: Row(
              children: [
                _AdminNavItem(
                  icon: Icons.rate_review_outlined,
                  activeIcon: Icons.rate_review_rounded,
                  label: 'Review',
                  isSelected: currentTab == AdminTab.review,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () =>
                      ref.read(adminTabProvider.notifier).state = AdminTab.review,
                ),
                _AdminNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentTab == AdminTab.profile,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => ref.read(adminTabProvider.notifier).state =
                      AdminTab.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: AppDimensions.navIconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
