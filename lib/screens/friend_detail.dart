import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';
import '../widgets/premium_card.dart';

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
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            title: Text(
              friend.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (balance != 0)
                TextButton.icon(
                  onPressed: () async {
                    await controller.settleFull(friend.id);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    'Settle up',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.success),
                ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionSheet(context, balance),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              'Add Transaction',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ).animate().scale(delay: 500.ms),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                BalanceCard(balance: balance).animate().fadeIn().slideY(begin: -0.1, end: 0),
                const SizedBox(height: 24),
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
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            final settled = controller.balanceForFriend(friend.id) == 0;
                            final owesYou = tx.delta >= 0;
                            
                            return PremiumCard(
                              onTap: () {}, // Maybe details?
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (owesYou ? AppColors.success : AppColors.error).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      owesYou ? Icons.arrow_outward : Icons.arrow_downward,
                                      color: owesYou ? AppColors.success : AppColors.error,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.description,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: settled ? TextDecoration.lineThrough : null,
                                            color: settled 
                                                ? AppColors.textSecondaryLight 
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${formatDateShort(tx.date)} • ${labelForType(tx.type)}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatSignedAmount(tx.delta),
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: settled 
                                              ? AppColors.textSecondaryLight
                                              : (owesYou ? AppColors.success : AppColors.error),
                                          decoration: settled ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Quick delete hidden (handled via logic? Original had LongPress)
                                  // We can add a popup menu or swipe action.
                                  // For simplicity, let's add a small more icon
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        onTap: () => _confirmDelete(context, tx.id, tx.description),
                                        child: Text('Delete', style: GoogleFonts.outfit(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
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
          child: AddTransactionSheet(
            controller: controller,
            friend: friend,
            currentBalance: currentBalance,
          ),
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
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete transaction?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Remove "$description" from the ledger?', style: GoogleFonts.outfit()),
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
            'New Transaction',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TransactionType.values
                  .where((t) => t != TransactionType.autoSubscription)
                  .map((type) {
                    final selected = _type == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(labelForType(type)),
                        selected: selected,
                        onSelected: (_) => setState(() => _type = type),
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
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: 'Rs ',
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
            controller: _descriptionController,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'What for?',
              hintText: 'Dinner, Movie, etc.',
              labelStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 12),
                  Text(
                    formatDateShort(_date),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
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
                  : Text('Save Transaction', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
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
           SnackBar(content: Text('Enter amount and reason', style: GoogleFonts.outfit())),
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
