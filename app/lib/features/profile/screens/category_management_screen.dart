import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../cubit/categories_cubit.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesCubit()..load(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  Future<void> _delete(
    BuildContext context, {
    required String groupId,
    required Category cat,
  }) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deleteCategoryTitle,
      body: context.l10n.deleteCategoryBody(cat.name),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final err = await context.read<CategoriesCubit>().delete(
          groupId: groupId,
          categoryId: cat.id,
        );
    if (!context.mounted || err == null) return;
    showTabbySnack(context, context.l10nError(err));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.categoriesTitle)),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          return switch (state) {
            CategoriesLoading() => const TabbyLoading(),
            CategoriesError(:final message) => TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<CategoriesCubit>().load(),
              ),
            CategoriesLoaded(:final data) => _CategoriesList(
                data: data,
                onDelete: (groupId, cat) =>
                    _delete(context, groupId: groupId, cat: cat),
              ),
          };
        },
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({required this.data, required this.onDelete});

  final CategoriesLoadedData data;
  final void Function(String groupId, Category cat) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final groupsWithCustom = data.customByGroup.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (groupsWithCustom.isEmpty) {
      return TabbyEmptyState(
        icon: Symbols.category_rounded,
        title: context.l10n.noCustomCategories,
        body: context.l10n.noCustomCategoriesHint,
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: groupsWithCustom.map((entry) {
        final groupId = entry.key;
        final cats = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                data.groupNames[groupId] ?? groupId,
                style: tt.titleMedium,
              ),
            ),
            TabbyListCard(
              child: Column(
                children: cats.asMap().entries.map((e) {
                  final i = e.key;
                  final cat = e.value;
                  return Column(
                    children: [
                      ListTile(
                        leading: TabbyCategoryGlyph(
                          icon: cat.flutterIcon,
                          background: context.tabbySemantic.chartColorFor(cat),
                          foreground: context.tabbySemantic.onFor(
                            context.tabbySemantic.chartColorFor(cat),
                            cs,
                          ),
                          size: 36,
                          iconSize: 20,
                        ),
                        title: Text(cat.name),
                        trailing: IconButton(
                          icon: Icon(
                            Symbols.delete_rounded,
                            size: 20,
                            color: cs.error,
                          ),
                          onPressed: () => onDelete(groupId, cat),
                        ),
                      ),
                      if (i < cats.length - 1)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: cs.outlineVariant,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
