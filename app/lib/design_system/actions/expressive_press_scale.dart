import 'package:material_ui/material_ui.dart';

/// Réduit légèrement le widget au press — feedback tactile M3 Expressive.
class ExpressivePressScale extends StatefulWidget {
  const ExpressivePressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
    this.onTap,
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final VoidCallback? onTap;

  @override
  State<ExpressivePressScale> createState() => _ExpressivePressScaleState();
}

class _ExpressivePressScaleState extends State<ExpressivePressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scaled = AnimatedScale(
      scale: _pressed && widget.enabled ? widget.scale : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: scaled,
      );
    }

    return Listener(
      onPointerDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      child: scaled,
    );
  }
}
