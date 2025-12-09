import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../widgets/common.dart';
import 'friend_detail.dart';
import 'subscriptions.dart';

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
          appBar: AppBar(
            title: const Text('Kanakku'),
            actions: [
              IconButton(
                tooltip: 'Subscriptions',
                icon: const Icon(Icons.receipt_long),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubscriptionScreen(controller: controller),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddFriendDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add friend'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TotalHeader(net: net),
                const SizedBox(height: 16),
                Expanded(
                  child: controller.friends.isEmpty
                      ? EmptyState(
                          title: 'No friends yet',
                          message:
                              'Add your friends to start tracking shared expenses.',
                          actionLabel: 'Add friend',
                          onAction: () => _showAddFriendDialog(context),
                        )
                      : ListView.separated(
                          itemCount: controller.friends.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final friend = controller.friends[index];
                            final balance = controller.balanceForFriend(friend.id);
                            return ListTile(
                              onLongPress: () =>
                                  _confirmDeleteFriend(context, friend),
                              title: Text(friend.name),
                              subtitle: const Text('Net balance'),
                              trailing: Text(
                                formatSignedAmount(balance),
                                style: TextStyle(
                                  color: balance >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final textController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add friend'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Person name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
        content: Text('Delete "${friend.name}" and all their transactions?'),
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
