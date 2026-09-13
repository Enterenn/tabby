part of 'add_expense_screen.dart';
// ─── Category rail (une seule catégorie par dépense) ─────────────────────────

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onCreate,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _CategoryRailAdd(onTap: onCreate);
          }
          final category = categories[index];
          return _CategoryRailItem(
            category: category,
            selected: selected?.id == category.id,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _CategoryRailItem extends StatelessWidget {
  const _CategoryRailItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final semantic = context.tabbySemantic;
    final color = semantic.chartColorFor(category);
    final onColor = semantic.onFor(color, cs);

    return SizedBox(
      width: 68,
      child: ExpressivePressScale(
        onTap: onTap,
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: selected ? 1 : 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                final size = 52.0 + 4.0 * t;
                return SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: ClipPath(
                      clipper: ExpressiveAccentClipper(
                        lobes: 8,
                        amplitude: 0.07 * t,
                        rotation: 0.12 * t,
                      ),
                      child: ColoredBox(
                        color: Color.lerp(cs.surfaceContainerLow, color, t)!,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Center(
                            child: category.iconWidget(
                              size: 22 + 2 * t,
                              color: Color.lerp(
                                cs.onSurfaceVariant,
                                onColor,
                                t,
                              ),
                              fill: t,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              context.categoryName(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRailAdd extends StatelessWidget {
  const _CategoryRailAdd({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return SizedBox(
      width: 68,
      child: ExpressivePressScale(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Center(
                child: Material(
                  color: cs.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: shapes.radiusLarge.topLeft,
                      topRight: shapes.radiusExtraLarge.topRight,
                      bottomRight: shapes.radiusMedium.bottomRight,
                      bottomLeft: shapes.radiusExtraLarge.bottomLeft,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Symbols.add_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.newFeminine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
