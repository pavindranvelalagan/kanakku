import 'package:flutter/material.dart';

import '../theme/colors.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = AppColors.primary;
    final inactiveColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.55) ??
        scheme.onSurfaceVariant;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              icon: Icons.group_outlined,
              index: 0,
              currentIndex: currentIndex,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              index: 1,
              currentIndex: currentIndex,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.arrow_downward_outlined,
              index: 2,
              currentIndex: currentIndex,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.arrow_upward_outlined,
              index: 3,
              currentIndex: currentIndex,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.person_outline,
              index: 4,
              currentIndex: currentIndex,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final int index;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(
        icon,
        color: selected ? activeColor : inactiveColor,
        size: 24,
      ),
    );
  }
}
