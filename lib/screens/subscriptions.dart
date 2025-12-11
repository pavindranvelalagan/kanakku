import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';
import '../widgets/premium_card.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSubscriptionSheet(context),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text('New Plan', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ).animate().scale(delay: 500.ms),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Subscriptions',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Auto-bill your friends monthly',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
              controller.subscriptions.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        title: 'No subscriptions',
                        message: 'Add a plan to auto-bill friends each month.',
                        actionLabel: 'Add plan',
                        onAction: () => _showAddSubscriptionSheet(context),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final plan = controller.subscriptions[index];
                          final members = plan.memberIds
                              .map(
                                (id) => controller.friends
                                    .firstWhere(
                                      (f) => f.id == id,
                                      orElse: () => Friend(
                                        id: id,
                                        name: 'Unknown',
                                        createdAt: DateTime.now(),
                                      ),
                                    )
                                    .name,
                              )
                              .toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                            child: PremiumCard(
                              onTap: () {}, // Maybe details or edit?
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PopupMenuButton(
                                        icon: const Icon(Icons.more_horiz, color: Colors.grey),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            onTap: () => _confirmDelete(context, plan),
                                            child: Text('Delete', style: GoogleFonts.outfit(color: AppColors.error)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rs ${plan.amountPerMember} / member',
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.group_outlined, size: 16, color: AppColors.textSecondaryLight),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          members.join(', '),
                                          style: GoogleFonts.outfit(
                                            color: AppColors.textSecondaryLight,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.history, size: 16, color: AppColors.textSecondaryLight),
                                      const SizedBox(width: 8),
                                      Text(
                                        plan.lastBilledMonth.isEmpty
                                            ? 'Not billed yet'
                                            : 'Last billed: ${plan.lastBilledMonth}',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textSecondaryLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05, end: 0),
                          );
                        },
                        childCount: controller.subscriptions.length,
                      ),
                    ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddSubscriptionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: AddSubscriptionSheet(controller: controller),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete subscription?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Delete "${plan.name}" and its future charges?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteSubscription(plan.id);
    }
  }
}

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'New Subscription',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Plan Name',
              hintText: 'Netflix, Spotify, etc.',
              labelStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Amount per member',
              prefixText: 'Rs ',
              labelStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Who shares this?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.friends
                .map(
                  (friend) {
                    final selected = _selectedFriendIds.contains(friend.id);
                    return FilterChip(
                      label: Text(friend.name),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedFriendIds.add(friend.id);
                          } else {
                            _selectedFriendIds.remove(friend.id);
                          }
                        });
                      },
                      backgroundColor: AppColors.surfaceLight,
                      selectedColor: AppColors.primary.withOpacity(0.1),
                      labelStyle: GoogleFonts.outfit(
                        color: selected ? AppColors.primary : AppColors.textSecondaryLight,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), 
                        side: BorderSide(color: selected ? AppColors.primary : Colors.transparent),
                      ),
                      showCheckmark: false,
                      side: BorderSide.none, 
                    );
                  },
                )
                .toList().cast<Widget>(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Create Plan', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null || amount <= 0 || _selectedFriendIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Add name, amount, and pick members', style: GoogleFonts.outfit())),
        );
      }
      return;
    }
    setState(() => _saving = true);
    await widget.controller.addSubscriptionPlan(
      name: name,
      amountPerMember: amount,
      memberIds: _selectedFriendIds.toList(),
    );
    if (mounted) Navigator.pop(context);
  }
}
