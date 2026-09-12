import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {
  // groupId → liste de catégories custom
  final Map<String, List<Category>> _customByGroup = {};
  final Map<String, String> _groupNames = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Récupérer tous les groupes de l'utilisateur
      final groupsResp = await apiClient.dio.get('/groups');
      final groups = (groupsResp.data as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList();

      final Map<String, List<Category>> result = {};
      for (final g in groups) {
        _groupNames[g.id] = g.name;
        final catsResp = await apiClient.dio.get(
          '/categories',
          queryParameters: {'group_id': g.id},
        );
        final all = (catsResp.data as List)
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList();
        // Garder seulement les catégories custom (non-default)
        result[g.id] = all.where((c) => !c.isDefault).toList();
      }

      setState(() {
        _customByGroup.clear();
        _customByGroup.addAll(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiFailure.from(e).message;
        _loading = false;
      });
    }
  }

  Future<void> _delete(String groupId, Category cat) async {
    final confirmed = await showTabbyConfirm(
      context,
      title: context.l10n.deleteCategoryTitle,
      body: context.l10n.deleteCategoryBody(cat.name),
      confirmLabel: context.l10n.delete,
      danger: true,
    );
    if (!confirmed) return;

    try {
      await apiClient.dio.delete('/categories/${cat.id}');
      setState(() {
        _customByGroup[groupId]?.removeWhere((c) => c.id == cat.id);
      });
    } catch (_) {
      if (mounted) {
        showTabbySnack(context, context.l10n.errorDelete);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.categoriesTitle)),
      body: _loading
          ? const TabbyLoading()
          : _error != null
              ? TabbyErrorState(
                  message: context.l10nError(_error),
                  retryLabel: context.l10n.retry,
                  onRetry: _load,
                )
              : _buildList(context, cs, tt),
    );
  }

  Widget _buildList(BuildContext context, ColorScheme cs, TextTheme tt) {
    // Filtrer les groupes qui ont au moins une catégorie custom
    final groupsWithCustom = _customByGroup.entries
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
                _groupNames[groupId] ?? groupId,
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
                          icon: Icon(Symbols.delete_rounded,
                              size: 20, color: cs.error),
                          onPressed: () => _delete(groupId, cat),
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
