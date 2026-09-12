import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

/// Scale au press via le ressort **spatial fast** M3 Expressive.
///
/// Le scale est un mouvement spatial (taille). M3 recommande un spring, pas
/// easing+durée : [md.sys.motion.spring.fast.spatial] (stiffness 800, damping 0.6)
/// pour les petits éléments — overshoot visible, puis repos.
///
/// Voir https://m3.material.io/styles/motion/overview/how-it-works
class ExpressivePressScale extends StatefulWidget {
  const ExpressivePressScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;

  @override
  State<ExpressivePressScale> createState() => _ExpressivePressScaleState();
}

class _ExpressivePressScaleState extends State<ExpressivePressScale>
    with SingleTickerProviderStateMixin {
  /// Token Expressif *fast spatial* (damping ratio, pas le coefficient Flutter).
  static final SpringDescription _fastSpatial =
      SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 800,
    ratio: 0.6,
  );

  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this)..value = 1;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _scale.animateWith(
      SpringSimulation(
        _fastSpatial,
        _scale.value,
        target,
        _scale.velocity,
      ),
    );
  }

  void _press() {
    if (!widget.enabled) return;
    _animateTo(widget.pressedScale);
  }

  void _release() {
    _animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final scaled = ScaleTransition(scale: _scale, child: widget.child);

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => _press() : null,
        onTapUp: widget.enabled ? (_) => _release() : null,
        onTapCancel: widget.enabled ? _release : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: scaled,
      );
    }

    return Listener(
      onPointerDown: widget.enabled ? (_) => _press() : null,
      onPointerUp: widget.enabled ? (_) => _release() : null,
      onPointerCancel: widget.enabled ? (_) => _release() : null,
      child: scaled,
    );
  }
}
