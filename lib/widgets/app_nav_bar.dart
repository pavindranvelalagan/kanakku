import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarItem(
            icon: Icons.group_outlined,
            selectedIcon: Icons.group_rounded,
            index: 0,
            isSelected: currentIndex == 0,
            onTap: onTap,
          ),
          _NavBarItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            index: 1,
            isSelected: currentIndex == 1,
            onTap: onTap,
          ),
          _NavBarItem(
            icon: Icons.arrow_downward_outlined, // You Owe
            selectedIcon: Icons.arrow_downward_rounded,
            index: 2,
            isSelected: currentIndex == 2,
            onTap: onTap,
          ),
          _NavBarItem(
            icon: Icons.arrow_upward_outlined, // Owed To You
            selectedIcon: Icons.arrow_upward_rounded,
            index: 3,
            isSelected: currentIndex == 3,
            onTap: onTap,
          ),
          _NavBarItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            index: 4,
            isSelected: currentIndex == 4,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = AppColors.primary;
    final inactiveColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          width: isSelected ? 48 : 32,
          height: isSelected ? 48 : 32,
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          ).animate(target: isSelected ? 1 : 0).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 200.ms,
          ),
        ),
      ),
    );
  }
}
