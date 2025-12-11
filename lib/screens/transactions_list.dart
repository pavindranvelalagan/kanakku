import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/premium_card.dart';

enum TransactionFilter { youOwe, owedToYou }

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({
    super.key,
    required this.controller,
    required this.filter,
  });

  final LedgerController controller;
  final TransactionFilter filter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final muted = textTheme.bodySmall?.color?.withOpacity(0.65) ??
            scheme.onSurfaceVariant;
        final txs = filter == TransactionFilter.youOwe
            ? controller.owedByYou()
            : controller.owedToYou();
        final title =
            filter == TransactionFilter.youOwe ? 'You owe these' : 'They owe you';

        return Scaffold(
          backgroundColor: scheme.surface,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: txs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: muted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No transactions found.',
                                style: textTheme.bodyMedium?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: txs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            final friend = controller.friends.firstWhere(
                                (f) => f.id == tx.friendId,
                                orElse: () => Friend(
                                      id: tx.friendId,
                                      name: 'Unknown',
                                      createdAt: DateTime.now(),
                                    ));
                            final settled =
                                controller.balanceForFriend(friend.id) == 0;
                            final owesYou = tx.delta >= 0;
                            final amountColor =
                                settled ? muted : (owesYou ? scheme.primary : AppColors.error);

                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 140),
                              child: PremiumCard(
                                key: ValueKey('${tx.id}-$settled'),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: amountColor.withOpacity(0.1),
                                      child: Text(
                                        (friend.name.isNotEmpty
                                                ? friend.name[0]
                                                : '?')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: amountColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            friend.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: settled
                                                      ? muted
                                                      : scheme.onSurface,
                                                  decoration: settled
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${formatDateShort(tx.date)} - ${tx.description}',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: muted,
                                              decoration: settled
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatSignedAmount(tx.delta),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: amountColor,
                                            decoration: settled
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                    ),
                                  ],
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
}
