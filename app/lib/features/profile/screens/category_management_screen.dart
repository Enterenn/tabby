import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(String groupId, Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text(
            'La catégorie "${cat.name}" sera supprimée. '
            'Les dépenses associées conserveront leur catégorie.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.dio.delete('/categories/${cat.id}');
      setState(() {
        _customByGroup[groupId]?.removeWhere((c) => c.id == cat.id);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes catégories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.category_rounded, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text('Aucune catégorie personnalisée',
                style: tt.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Crée des catégories depuis l\'écran\nNouvelle dépense',
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            Card(
              child: Column(
                children: cats.asMap().entries.map((e) {
                  final i = e.key;
                  final cat = e.value;
                  return Column(
                    children: [
                      ListTile(
                        leading: Material(
                          color: cat.flutterColor.withValues(alpha: 0.15),
                          shape: context.tabbyShapes.circle(),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: cat.iconWidget(
                                size: 20,
                                color: cat.flutterColor,
                              ),
                            ),
                          ),
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
