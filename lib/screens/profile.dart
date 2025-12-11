import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final name = controller.settings.userName.trim();
        final totalPositive = controller
            .transactions
            .where((t) => t.delta > 0)
            .fold<int>(0, (a, b) => a + b.delta);
        final totalNegative = controller
            .transactions
            .where((t) => t.delta < 0)
            .fold<int>(0, (a, b) => a + b.delta.abs());
        final maxValue =
            [totalPositive.abs(), totalNegative.abs(), 1].reduce((a, b) => a > b ? a : b);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      (name.isNotEmpty ? name[0] : 'K').toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? "Tap to set your name" : name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => _promptName(context),
                          child: const Text('Edit name'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'History snapshot',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _BarRow(
                label: 'You should receive',
                value: totalPositive,
                maxValue: maxValue,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 8),
              _BarRow(
                label: 'You should pay',
                value: totalNegative,
                maxValue: maxValue,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                "App title preview",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                controller.effectiveAppTitle(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptName(BuildContext context) async {
    final textController = TextEditingController(text: controller.settings.userName);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Pavindran',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.setUserName(textController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (value.abs() / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value == 0 ? '0' : formatSignedAmount(value)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
