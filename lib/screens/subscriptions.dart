import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';
import '../widgets/premium_card.dart';

enum SubscriptionMode { iPay, friendPays }

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65) ??
        scheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: scheme.surface,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddSubscriptionSheet(context),
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscriptions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: controller.subscriptions.isEmpty
                      ? EmptyState(
                          title: 'No subscriptions',
                          message: 'Add a plan to auto-bill friends each month.',
                          actionLabel: 'Add plan',
                          onAction: () => _showAddSubscriptionSheet(context),
                        )
                      : ListView.separated(
                          itemCount: controller.subscriptions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
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
                            final payerName = plan.paidByMe
                                ? 'You pay total'
                                : controller.friends
                                        .firstWhere(
                                          (f) => f.id == plan.payerId,
                                          orElse: () => Friend(
                                            id: plan.payerId ?? '',
                                            name: 'Unknown payer',
                                            createdAt: DateTime.now(),
                                          ),
                                        )
                                        .name;
                            return PremiumCard(
                              padding: const EdgeInsets.all(16),
                              onLongPress: () => _confirmDelete(context, plan),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      plan.name.isNotEmpty
                                          ? plan.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs ${plan.amountPerMember} per member',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          payerName,
                                          style: GoogleFonts.outfit(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (plan.paidByMe) ...[
                                          Text(
                                            members.join(', '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              color: muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          plan.lastBilledMonth.isEmpty
                                              ? 'Not billed yet'
                                              : 'Billed ${plan.lastBilledMonth}',
                                          style: GoogleFonts.outfit(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
        title: const Text('Delete subscription?'),
        content: Text('Delete "${plan.name}" and its future charges?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
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
  SubscriptionMode _mode = SubscriptionMode.iPay;
  String? _payerFriendId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.controller.friends;
    final hasFriends = friends.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final muted =
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65) ??
            scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ToggleButtons(
            isSelected: [
              _mode == SubscriptionMode.iPay,
              _mode == SubscriptionMode.friendPays,
            ],
            onPressed: (index) {
              setState(() {
                _mode = index == 0
                    ? SubscriptionMode.iPay
                    : SubscriptionMode.friendPays;
              });
            },
            borderRadius: BorderRadius.circular(12),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('I pay'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Friend pays'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'New Subscription',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Plan Name',
              hintText: 'Netflix, Spotify, etc.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _mode == SubscriptionMode.iPay
                  ? 'Amount per member'
                  : 'Your monthly share',
              prefixText: 'Rs ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          if (_mode == SubscriptionMode.iPay) ...[
            Text(
              'Who shares this?',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasFriends)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Add friends first to assign members.',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: friends.map((friend) {
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
                  backgroundColor: scheme.surface,
                  selectedColor: scheme.primary.withOpacity(0.12),
                  labelStyle: GoogleFonts.outfit(
                    color: selected ? scheme.primary : muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selected ? scheme.primary : Colors.transparent,
                    ),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              'Who pays the total?',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _payerFriendId,
              items: friends
                  .map(
                    (f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _payerFriendId = value),
              decoration: const InputDecoration(
                labelText: 'Select friend',
                border: OutlineInputBorder(),
              ),
            ),
            if (!hasFriends)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add friends first to pick a payer.',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving || !hasFriends ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Create Plan',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    final friends = widget.controller.friends;

    if (name.isEmpty || amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a name and valid amount')),
        );
      }
      return;
    }

    if (_mode == SubscriptionMode.iPay) {
      if (_selectedFriendIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pick at least one member')),
          );
        }
        return;
      }
      setState(() => _saving = true);
      await widget.controller.addSubscriptionPlan(
        name: name,
        amountPerMember: amount,
        memberIds: _selectedFriendIds.toList(),
        paidByMe: true,
      );
    } else {
      if (friends.isEmpty || (_payerFriendId ?? '').isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select who pays the total')),
          );
        }
        return;
      }
      setState(() => _saving = true);
      await widget.controller.addSubscriptionPlan(
        name: name,
        amountPerMember: amount,
        memberIds: const [],
        paidByMe: false,
        payerId: _payerFriendId,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
