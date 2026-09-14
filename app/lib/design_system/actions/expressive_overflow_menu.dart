import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';

class ExpressiveOverflowAction {
  const ExpressiveOverflowAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;
}

/// Overflow M3 Expressive — `more_vert` sans fond, menu calé sous le bouton.
class ExpressiveOverflowMenu extends StatefulWidget {
  const ExpressiveOverflowMenu({
    super.key,
    required this.actions,
    this.tooltip,
  });

  final List<ExpressiveOverflowAction> actions;
  final String? tooltip;

  @override
  State<ExpressiveOverflowMenu> createState() => _ExpressiveOverflowMenuState();
}

class _ExpressiveOverflowMenuState extends State<ExpressiveOverflowMenu> {
  final OverlayPortalController _controller = OverlayPortalController();

  void _toggle() {
    if (_controller.isShowing) {
      _controller.hide();
    } else {
      _controller.show();
    }
  }

  void _hide() {
    if (_controller.isShowing) _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;

    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (overlayContext) {
        return InheritedTheme.captureAll(
          context,
          _OverflowMenuOverlay(
            anchorContext: context,
            actions: widget.actions,
            onDismiss: _hide,
          ),
        );
      },
      child: IconButton(
        tooltip: widget.tooltip,
        onPressed: _toggle,
        icon: Icon(Symbols.more_vert_rounded, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _OverflowMenuOverlay extends StatelessWidget {
  const _OverflowMenuOverlay({
    required this.anchorContext,
    required this.actions,
    required this.onDismiss,
  });

  final BuildContext anchorContext;
  final List<ExpressiveOverflowAction> actions;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final overlayBox =
        Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
    final buttonBox = anchorContext.findRenderObject() as RenderBox?;
    if (overlayBox == null || buttonBox == null || !buttonBox.hasSize) {
      return const SizedBox.shrink();
    }

    final origin = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchor = origin & buttonBox.size;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
            ),
          ),
          CustomSingleChildLayout(
            delegate: _BelowEndDelegate(
              anchor: anchor,
              overlaySize: overlayBox.size,
            ),
            child: _OverflowMenuPanel(actions: actions, onDismiss: onDismiss),
          ),
        ],
      ),
    );
  }
}

class _BelowEndDelegate extends SingleChildLayoutDelegate {
  const _BelowEndDelegate({required this.anchor, required this.overlaySize});

  final Rect anchor;
  final Size overlaySize;

  static const _gapBelow = 10.0;
  static const _shiftRight = 24.0;
  static const _inset = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: overlaySize.width - _inset * 2,
      maxHeight: overlaySize.height - _inset * 2,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.right - childSize.width + _shiftRight;
    var y = anchor.bottom + _gapBelow;

    if (x + childSize.width > overlaySize.width - _inset) {
      x = overlaySize.width - _inset - childSize.width;
    }
    if (x < _inset) x = _inset;

    if (y + childSize.height > overlaySize.height - _inset) {
      y = anchor.top - childSize.height - _gapBelow;
    }
    if (y < _inset) y = _inset;

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_BelowEndDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        overlaySize != oldDelegate.overlaySize;
  }
}

class _OverflowMenuPanel extends StatelessWidget {
  const _OverflowMenuPanel({required this.actions, required this.onDismiss});

  final List<ExpressiveOverflowAction> actions;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return Material(
      color: cs.surfaceContainerLow,
      elevation: 4,
      shadowColor: cs.shadow.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: shapes.radiusExtraLarge),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0 && actions[i].danger && !actions[i - 1].danger)
                  Divider(
                    height: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.6),
                  ),
                _OverflowMenuItem(action: actions[i], onDismiss: onDismiss),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverflowMenuItem extends StatelessWidget {
  const _OverflowMenuItem({required this.action, required this.onDismiss});

  final ExpressiveOverflowAction action;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final color = action.danger ? cs.error : cs.onSurface;

    return InkWell(
      onTap: () {
        onDismiss();
        action.onTap();
      },
      borderRadius: shapes.radiusLarge,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, color: color),
              const SizedBox(width: 12),
            ],
            Text(action.label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
