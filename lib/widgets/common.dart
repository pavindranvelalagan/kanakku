import 'package:flutter/material.dart';

import '../models.dart';

class TotalHeader extends StatelessWidget {
  const TotalHeader({super.key, required this.net});
  final int net;

  @override
  Widget build(BuildContext context) {
    final owesYou = net >= 0;
    final label = owesYou ? 'Total owed to you' : 'Total you owe';
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor =
        colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white;
    final labelColor = colorScheme.onSurface;
    final amountColor =
        owesYou ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.8);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              colorScheme.brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: colorScheme.brightness == Brightness.dark ? 2 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: labelColor,
              )),
          Text(
            formatSignedAmount(net),
            style: TextStyle(
              color: amountColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              scheme.brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: scheme.brightness == Brightness.dark ? 2 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Net balance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            formatSignedAmount(balance),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: balance >= 0
                  ? scheme.primary
                  : scheme.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
