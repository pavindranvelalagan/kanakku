import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';

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
        final txs = filter == TransactionFilter.youOwe
            ? controller.owedByYou()
            : controller.owedToYou();
        final title = filter == TransactionFilter.youOwe
            ? 'You owe these'
            : 'They owe you';
        return Padding(
          padding: const EdgeInsets.all(16),
          child: txs.isEmpty
              ? Center(
                  child: Text(
                    'No transactions here yet.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: txs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = txs[index];
                          final friend =
                              controller.friends.firstWhere((f) => f.id == tx.friendId,
                                  orElse: () => Friend(
                                        id: tx.friendId,
                                        name: 'Unknown',
                                        createdAt: DateTime.now(),
                                      ));
                          final settled =
                              controller.balanceForFriend(friend.id) == 0;
                          final color = tx.delta >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700;
                          final strike = settled
                              ? TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                )
                              : null;
                          return ListTile(
                            title: Text(friend.name),
                            subtitle: Text(
                                '${formatDateShort(tx.date)} • ${tx.description}',
                                style: strike),
                            trailing: Text(
                              formatSignedAmount(tx.delta),
                              style: TextStyle(
                                color: settled ? Colors.grey : color,
                                fontWeight: FontWeight.w700,
                                decoration:
                                    settled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            textColor: settled ? Colors.grey : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
