import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../widgets/common.dart';

class FriendDetailScreen extends StatelessWidget {
  const FriendDetailScreen({
    super.key,
    required this.controller,
    required this.friend,
  });

  final LedgerController controller;
  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final balance = controller.balanceForFriend(friend.id);
        final txs = controller.transactionsForFriend(friend.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(friend.name),
            actions: [
              TextButton(
                onPressed: balance == 0
                    ? null
                    : () async {
                        await controller.settleFull(friend.id);
                      },
                child: const Text('Settle up'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionSheet(context, balance),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BalanceCard(balance: balance),
                const SizedBox(height: 16),
                Expanded(
                  child: txs.isEmpty
                      ? EmptyState(
                          title: 'No transactions',
                          message: 'Start by adding a payment or subscription.',
                          actionLabel: 'Add transaction',
                          onAction: () =>
                              _showAddTransactionSheet(context, balance),
                        )
                      : ListView.separated(
                          itemCount: txs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            final color = tx.delta >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700;
                            return ListTile(
                              onLongPress: () =>
                                  _confirmDelete(context, tx.id, tx.description),
                              title: Text(tx.description),
                              subtitle: Text(
                                '${formatDateShort(tx.date)} • ${labelForType(tx.type)}',
                              ),
                              trailing: Text(
                                formatSignedAmount(tx.delta),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
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

  Future<void> _showAddTransactionSheet(
    BuildContext context,
    int currentBalance,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionSheet(
          controller: controller,
          friend: friend,
          currentBalance: currentBalance,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String txId,
    String description,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('Remove "$description" from the ledger?'),
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
      await controller.deleteTransaction(txId);
    }
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.controller,
    required this.friend,
    required this.currentBalance,
  });

  final LedgerController controller;
  final Friend friend;
  final int currentBalance;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionType _type = TransactionType.paid;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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
            'Add transaction',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TransactionType.values
                .where((t) => t != TransactionType.autoSubscription)
                .map(
                  (type) => ChoiceChip(
                    label: Text(labelForType(type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Text(
            'Partial payment reduces only part of the outstanding balance without clearing it.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (Rs)',
              hintText: '850',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'YouTube plan / Lunch / Bus ticket',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Date'),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: _date,
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
                child: Text(formatDateShort(_date)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    final amount = int.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    if (amount == null || amount <= 0 || description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter amount and reason')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    await widget.controller.addTransactionForFriend(
      friendId: widget.friend.id,
      type: _type,
      amount: amount,
      description: description,
      date: _date,
      currentBalance: widget.currentBalance,
    );
    if (mounted) Navigator.pop(context);
  }
}
