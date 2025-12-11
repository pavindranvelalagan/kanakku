import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
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
        final txs = filter == TransactionFilter.youOwe
            ? controller.owedByYou()
            : controller.owedToYou();
        final title = filter == TransactionFilter.youOwe
            ? 'You owe these'
            : 'They owe you';
        
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
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
                                color: Colors.grey.withOpacity(0.3)
                              ).animate().scale(),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found.',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textSecondaryLight,
                                  fontSize: 16,
                                ),
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
                            final friend =
                                controller.friends.firstWhere((f) => f.id == tx.friendId,
                                    orElse: () => Friend(
                                          id: tx.friendId,
                                          name: 'Unknown',
                                          createdAt: DateTime.now(),
                                        ));
                            final settled =
                                controller.balanceForFriend(friend.id) == 0;
                            
                            final owesYou = tx.delta >= 0;

                            return PremiumCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (owesYou ? AppColors.success : AppColors.error).withOpacity(0.1),
                                    child: Text(
                                      (friend.name.isNotEmpty ? friend.name[0] : '?').toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        color: owesYou ? AppColors.success : AppColors.error,
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
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: settled ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                                            decoration: settled ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${formatDateShort(tx.date)} • ${tx.description}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryLight,
                                            decoration: settled ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatSignedAmount(tx.delta),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: settled 
                                          ? AppColors.textSecondaryLight 
                                          : (owesYou ? AppColors.success : AppColors.error),
                                      decoration: settled ? TextDecoration.lineThrough : null,
                                    ),
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
}
