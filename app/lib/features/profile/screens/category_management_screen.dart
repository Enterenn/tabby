import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/category_editor_sheet.dart';
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

  Future<void> _edit(BuildContext context, Category cat) {
    return showCategoryEditorSheet(
      context: context,
      initial: cat,
      onSubmit: ({
        required name,
        required icon,
        required color,
      }) {
        return context.read<CategoriesCubit>().update(
              categoryId: cat.id,
              name: name,
              icon: icon,
              color: color,
            );
      },
    );
  }

  Future<void> _delete(BuildContext context, Category cat) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deleteCategoryTitle,
      body: context.l10n.deleteCategoryBody(context.categoryName(cat)),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final err = await context.read<CategoriesCubit>().delete(
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
            CategoriesLoaded(:final custom) => _CategoriesList(
                custom: custom,
                onEdit: (cat) => _edit(context, cat),
                onDelete: (cat) => _delete(context, cat),
              ),
          };
        },
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({
    required this.custom,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Category> custom;
  final void Function(Category cat) onEdit;
  final void Function(Category cat) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (custom.isEmpty) {
      return TabbyEmptyState(
        icon: Symbols.category_rounded,
        title: context.l10n.noCustomCategories,
        body: context.l10n.noCustomCategoriesHint,
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        TabbyListCard(
          child: Column(
            children: [
              for (var i = 0; i < custom.length; i++) ...[
                ListTile(
                  onTap: () => onEdit(custom[i]),
                  leading: TabbyCategoryGlyph(
                    icon: custom[i].flutterIcon,
                    background: context.tabbySemantic.chartColorFor(custom[i]),
                    foreground: context.tabbySemantic.onFor(
                      context.tabbySemantic.chartColorFor(custom[i]),
                      cs,
                    ),
                    size: 36,
                    iconSize: 20,
                  ),
                  title: Text(context.categoryName(custom[i])),
                  trailing: ExpressiveOverflowMenu(
                    tooltip: context.l10n.moreOptions,
                    actions: [
                      ExpressiveOverflowAction(
                        label: context.l10n.edit,
                        icon: Symbols.edit_rounded,
                        onTap: () => onEdit(custom[i]),
                      ),
                      ExpressiveOverflowAction(
                        label: context.l10n.delete,
                        icon: Symbols.delete_rounded,
                        danger: true,
                        onTap: () => onDelete(custom[i]),
                      ),
                    ],
                  ),
                ),
                if (i < custom.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
