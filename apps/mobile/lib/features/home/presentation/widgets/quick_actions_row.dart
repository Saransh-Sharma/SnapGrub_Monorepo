import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.go('/meal-editor'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Manual'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/journal'),
            icon: const Icon(Icons.list_alt),
            label: const Text('Journal'),
          ),
        ),
      ],
    );
  }
}
