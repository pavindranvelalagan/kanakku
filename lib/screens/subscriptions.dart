import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../widgets/common.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: controller.subscriptions.isEmpty
                  ? EmptyState(
                      title: 'No subscriptions',
                      message: 'Add a plan to auto-bill friends each month.',
                      actionLabel: 'Add plan',
                      onAction: () => _showAddSubscriptionSheet(context),
                    )
                  : ListView.separated(
                      itemCount: controller.subscriptions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
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
                        return ListTile(
                          onLongPress: () => _confirmDelete(context, plan),
                          title: Text(plan.name),
                          subtitle: Text(
                            'Rs ${plan.amountPerMember} per member • ${members.join(', ')}',
                          ),
                          trailing: Text(
                            plan.lastBilledMonth.isEmpty
                                ? 'Not billed yet'
                                : 'Billed ${plan.lastBilledMonth}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _showAddSubscriptionSheet(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSubscriptionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddSubscriptionSheet(controller: controller),
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
              backgroundColor: Colors.red,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add subscription',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Plan name',
              hintText: 'YouTube Family',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount per member (Rs)',
              hintText: '850',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Members',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.controller.friends
                .map(
                  (friend) => FilterChip(
                    label: Text(friend.name),
                    selected: _selectedFriendIds.contains(friend.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFriendIds.add(friend.id);
                        } else {
                          _selectedFriendIds.remove(friend.id);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
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
          const SnackBar(content: Text('Add name, amount, and pick members')),
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
