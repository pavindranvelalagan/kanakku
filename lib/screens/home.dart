import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';
import '../widgets/premium_card.dart';
import 'friend_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final net = controller.totalNetBalance();
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddFriendDialog(context),
            backgroundColor: Colors.black,
            child: const Icon(Icons.add, color: Colors.white),
          ).animate().scale(delay: 500.ms),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, There!',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dashboard',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.backgroundLight,
                          radius: 24,
                          backgroundImage: 
                              const NetworkImage('https://i.pravatar.cc/150?img=12'), // Placeholder or Initials
                          // If offline, use Initials
                          child: const Icon(Icons.person, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TotalHeader(net: net),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Friends',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () {}, // Maybe View All?
                          child: Text(
                            'View All',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              controller.friends.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        title: 'No friends yet',
                        message: 'Add your friends to start tracking shared expenses.',
                        actionLabel: 'Add friend',
                        onAction: () => _showAddFriendDialog(context),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final friend = controller.friends[index];
                          final balance = controller.balanceForFriend(friend.id);
                          final owesYou = balance >= 0;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                            child: PremiumCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FriendDetailScreen(
                                      controller: controller,
                                      friend: friend,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to view details',
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
                                        formatSignedAmount(balance),
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: owesYou ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        owesYou ? 'owed' : 'due',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0),
                          );
                        },
                        childCount: controller.friends.length,
                      ),
                    ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // Space for NavBar
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final textController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add friend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: GoogleFonts.outfit(),
            hintText: 'Person name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
              if (textController.text.trim().isEmpty) return;
              await controller.createFriend(textController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteFriend(BuildContext context, Friend friend) async {
    // Kept for reference but not attached in UI currently (except maybe friend detail)
  }
}
