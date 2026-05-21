import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/templates/data/template_repository.dart';
import 'package:snapgrub/features/templates/domain/meal_template.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextData = ref.watch(homeUserContextProvider);
    return AppScaffold(
      title: 'Templates',
      child: contextData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
        data: (data) {
          if (data == null) return const Text('Sign in to continue.');
          final templates = ref.watch(mealTemplatesProvider(data.userId));
          return templates.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
            data: (items) {
              if (items.isEmpty) return const Text('Save a meal as a template to reuse it here.');
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _TemplateTile(
                  template: items[index],
                  timezone: data.timezone,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({
    required this.template,
    required this.timezone,
  });

  final MealTemplate template;
  final String timezone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = template.snapshot['items'] as List? ?? const [];
    return Card(
      child: ListTile(
        title: Text(template.title),
        subtitle: Text('${items.length} items · ${template.syncStatus}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'use') {
              final meal = await ref.read(mealRepositoryProvider).saveDraft(template.toDraft(timezone: timezone));
              if (context.mounted) context.go('/meal-editor?id=${meal.id}');
            } else if (value == 'delete') {
              await ref.read(templateRepositoryProvider).delete(template);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'use', child: Text('Use template')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
