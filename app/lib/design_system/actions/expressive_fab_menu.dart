import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import 'expressive_action_button.dart';

/// Action du menu FAB M3 — icône + libellé.
class ExpressiveFabMenuAction {
  const ExpressiveFabMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
}

/// FAB menu M3 Expressive ancré en bas à droite.
///
/// Conforme au pattern [FAB menu M3](https://m3.material.io/components/fab-menu/overview) :
/// pills unifiés (icône + label), + → ×, scrim, animations décalées.
///
/// À placer dans un [Stack] qui remplit le [Scaffold.body].
class ExpressiveScreenFabMenu extends StatefulWidget {
  const ExpressiveScreenFabMenu({
    super.key,
    required this.actions,
    this.margin = const EdgeInsets.only(right: 16, bottom: 16),
    this.fabSize = 56,
  });

  final List<ExpressiveFabMenuAction> actions;
  final EdgeInsets margin;
  final double fabSize;

  @override
  State<ExpressiveScreenFabMenu> createState() => _ExpressiveScreenFabMenuState();
}

class _ExpressiveScreenFabMenuState extends State<ExpressiveScreenFabMenu>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;

  static const _itemSpacing = 16.0;
  static const _menuDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _menuDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.reverse();
  }

  void _select(ExpressiveFabMenuAction action) {
    _close();
    action.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.length == 1) {
      return Positioned(
        right: widget.margin.right,
        bottom: widget.margin.bottom,
        child: ExpressiveActionButton(
          icon: Symbols.add_rounded,
          size: widget.fabSize,
          tooltip: widget.actions.first.label,
          onPressed: widget.actions.first.onSelected,
        ),
      );
    }

    final cs = context.tabbyColors;

    return Stack(
      children: [
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: ColoredBox(
                  color: cs.scrim.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
        Positioned(
          right: widget.margin.right,
          bottom: widget.margin.bottom,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final showItems = _open || _controller.value > 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showItems) ...[
                    for (var i = 0; i < widget.actions.length; i++) ...[
                      _StaggeredFabMenuItem(
                        index: widget.actions.length - 1 - i,
                        total: widget.actions.length,
                        animation: _controller,
                        child: _FabMenuItemPill(
                          action: widget.actions[i],
                          onTap: () => _select(widget.actions[i]),
                        ),
                      ),
                      if (i < widget.actions.length - 1)
                        const SizedBox(height: _itemSpacing),
                    ],
                    const SizedBox(height: _itemSpacing),
                  ],
                  _FabMenuTrigger(
                    open: _open,
                    size: widget.fabSize,
                    onPressed: _toggle,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// FAB principal — + fermé (primary), × ouvert (contraste surface).
class _FabMenuTrigger extends StatelessWidget {
  const _FabMenuTrigger({
    required this.open,
    required this.size,
    required this.onPressed,
  });

  final bool open;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;

    return ExpressiveActionButton(
      icon: open ? Symbols.close_rounded : Symbols.add_rounded,
      size: size,
      color: open ? cs.surfaceContainerHighest : cs.primary,
      iconColor: open ? cs.onSurface : cs.onPrimary,
      tooltip: open ? context.l10n.fabClose : context.l10n.fabActions,
      onPressed: onPressed,
    );
  }
}

/// Item pill unifié M3 — icône + label dans une seule surface.
class _FabMenuItemPill extends StatelessWidget {
  const _FabMenuItemPill({
    required this.action,
    required this.onTap,
  });

  final ExpressiveFabMenuAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;
    const height = 56.0;

    return Material(
      color: cs.primaryContainer,
      elevation: 0,
      shape: shapes.pill(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shapes.pill(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 24,
                  fill: 1,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  action.label,
                  style: tt.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrée décalée — les items les plus proches du FAB apparaissent en premier.
class _StaggeredFabMenuItem extends StatelessWidget {
  const _StaggeredFabMenuItem({
    required this.index,
    required this.total,
    required this.animation,
    required this.child,
  });

  final int index;
  final int total;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.5);
    final end = (0.45 + index * 0.12).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
    );
  }
}
