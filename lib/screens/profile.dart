import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../widgets/premium_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final name = controller.settings.userName.trim();
        final totalPositive = controller
            .transactions
            .where((t) => t.delta > 0)
            .fold<int>(0, (a, b) => a + b.delta);
        final totalNegative = controller
            .transactions
            .where((t) => t.delta < 0)
            .fold<int>(0, (a, b) => a + b.delta.abs());
        final maxValue =
            [totalPositive.abs(), totalNegative.abs(), 1].reduce((a, b) => a > b ? a : b);

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            (name.isNotEmpty ? name[0] : 'K').toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => _promptName(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? "Set your name" : name,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 32),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Financial Snapshot',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _BarRow(
                        label: 'To Receive',
                        value: totalPositive,
                        maxValue: maxValue,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 24),
                      _BarRow(
                        label: 'To Pay',
                        value: totalNegative,
                        maxValue: maxValue,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0, delay: 100.ms),
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Appearance',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _ThemeSelector(controller: controller),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0, delay: 200.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptName(BuildContext context) async {
    final textController = TextEditingController(text: controller.settings.userName);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Name', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
            labelStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          maxLength: 40,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await controller.setUserName(textController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (value.abs() / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight)),
            Text(
              value == 0 ? '0' : formatSignedAmount(value),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio == 0 ? 0.01 : ratio, // Min width for visibility if 0? No, 0 is 0.
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.controller});
  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final current = controller.settings.themeMode;
    return Column(
      children: [
        _buildOption(context, 'system', 'System Default', Icons.brightness_auto, current),
        const Divider(height: 1, indent: 56, endIndent: 24),
        _buildOption(context, 'light', 'Light Mode', Icons.wb_sunny_rounded, current),
        const Divider(height: 1, indent: 56, endIndent: 24),
        _buildOption(context, 'dark', 'Dark Mode', Icons.nightlight_round, current),
      ],
    );
  }

  Widget _buildOption(BuildContext context, String value, String label, IconData icon, String current) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => controller.setThemeMode(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
