import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../storage.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
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
        final userName = controller.settings.userName.trim();
        final greeting = userName.isEmpty ? 'Hello, there!' : 'Hello, $userName!';
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final muted = scheme.onSurface.withOpacity(0.65);
        return Scaffold(
          backgroundColor: scheme.surface,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddFriendDialog(context),
            backgroundColor: scheme.primary,
            child: Icon(Icons.add, color: scheme.onPrimary),
          ),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dashboard',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TotalHeader(net: net),
                    const SizedBox(height: 20),
                    Text(
                      'Friends',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                              onLongPress: () => _confirmDeleteFriend(context, friend),
                              child: Row(
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: scheme.primary,
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
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to view details',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: muted,
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
                                          color: owesYou
                                              ? scheme.primary
                                              : AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        owesYou ? 'owed' : 'due',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
    final scheme = Theme.of(context).colorScheme;
    final muted =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
            scheme.onSurfaceVariant;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: scheme.surface,
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
            child: Text('Cancel', style: GoogleFonts.outfit(color: muted)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete friend?'),
        content: Text('Delete ${friend.name} and all their transactions?'),
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
      await controller.deleteFriend(friend.id);
    }
  }
}
