import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../models/loyalty_card.dart';
import 'loyalty_card_face.dart';

/// Pile wallet — peek assez haut pour lire logo + nom, puis resserre.
class LoyaltyWalletStack extends StatefulWidget {
  const LoyaltyWalletStack({
    super.key,
    required this.cards,
    required this.onTapCard,
    required this.onReorder,
  });

  final List<LoyaltyCard> cards;
  final void Function(LoyaltyCard card) onTapCard;
  final void Function(List<LoyaltyCard> newOrder) onReorder;

  static const fullHeight = LoyaltyCardLayout.cardHeight;

  /// Bande visible d'une carte selon sa profondeur (1 = juste derrière l'avant).
  /// Deux cartes lisibles (logo + nom), le reste à 20 px.
  static double peekForDepth(int depth) {
    return depth <= 2 ? 64 : 20;
  }

  @override
  State<LoyaltyWalletStack> createState() => _LoyaltyWalletStackState();
}

class _LoyaltyWalletStackState extends State<LoyaltyWalletStack>
    with TickerProviderStateMixin {
  static const _flyExtent = 1.4;
  static const _commitFraction = 0.28;
  static const _commitVelocity = 800.0;
  static const _maxTilt = 0.18;
  static const _inspectPeek = 72.0;
  static const _inspectFalloff = 1.7;
  static const _inspectLinger = Duration(milliseconds: 2000);
  static const _ballotDuration = Duration(milliseconds: 700);
  static const _breezeCurve = Cubic(0.37, 0.0, 0.63, 1);

  static final _snapSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.82,
  );

  late final AnimationController _slide;
  late final AnimationController _inspect;
  late final AnimationController _float;
  double _width = 0;
  double _focus = 0;
  int _lastFocusTick = -1;
  bool _flying = false;
  bool _inspecting = false;
  bool _lingering = false;
  Timer? _lingerTimer;

  List<LoyaltyCard> get _cards => widget.cards;
  int get _frontIndex => _cards.length - 1;

  bool get _inspectLive =>
      _inspecting ||
      _lingering ||
      _inspect.isAnimating ||
      _inspect.value.abs() > 0.001;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController.unbounded(vsync: this);
    _inspect = AnimationController.unbounded(vsync: this);
    _float = AnimationController(
      vsync: this,
      duration: _ballotDuration,
    );
  }

  @override
  void dispose() {
    _lingerTimer?.cancel();
    _float.dispose();
    _slide.dispose();
    _inspect.dispose();
    super.dispose();
  }

  double get _floatWave {
    if (_inspect.value.abs() < 0.001) return 0;
    return _breezeCurve.transform(_float.value) * 2 - 1;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_flying || _inspectLive || _cards.length < 2) return;
    _slide.stop();
    _slide.value += details.delta.dx;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_flying || _inspectLive || _cards.length < 2) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final dx = _slide.value;
    final commit =
        dx.abs() > _width * _commitFraction || vx.abs() > _commitVelocity;
    if (commit && (dx != 0 || vx != 0)) {
      final toRight = dx == 0 ? vx > 0 : dx > 0;
      _flyOff(toRight: toRight, velocity: vx);
    } else {
      _snapBack(vx);
    }
  }

  void _onDragCancel() {
    if (_flying || _inspectLive || _cards.length < 2) return;
    _snapBack(0);
  }

  void _snapBack(double velocity) {
    _slide.animateWith(
      SpringSimulation(_snapSpring, _slide.value, 0, velocity),
    );
  }

  Future<void> _flyOff({
    required bool toRight,
    required double velocity,
  }) async {
    if (_width <= 0) return;
    setState(() => _flying = true);
    final target = (toRight ? 1 : -1) * _width * _flyExtent;
    final ms = (320 - velocity.abs() / 18).clamp(180, 360).round();
    await _slide.animateTo(
      target,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    _slide.value = 0;
    setState(() => _flying = false);
    _sendFrontToBack();
  }

  void _sendFrontToBack() {
    if (_cards.length < 2) return;
    final list = List<LoyaltyCard>.from(_cards);
    final front = list.removeLast();
    list.insert(0, front);
    widget.onReorder(list);
  }

  void _bringToFront(int index) {
    if (index < 0 || index >= _cards.length - 1) return;
    final list = List<LoyaltyCard>.from(_cards);
    final card = list.removeAt(index);
    list.add(card);
    widget.onReorder(list);
  }

  void _cancelLinger() {
    _lingerTimer?.cancel();
    _lingerTimer = null;
    _lingering = false;
    if (_float.isAnimating) _float.stop();
  }

  void _dismissInspect() {
    _cancelLinger();
    if (!mounted) return;
    setState(() => _inspecting = false);
    _inspect.animateTo(
      0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
    );
  }

  void _onInspectStart(LongPressStartDetails details) {
    if (_flying || _cards.isEmpty || _slide.value.abs() > 8) return;
    _cancelLinger();
    _inspect.stop();
    _lastFocusTick = -1;
    _setFocus(_indexAt(details.localPosition.dy), snap: true);
    setState(() => _inspecting = true);
    HapticFeedback.mediumImpact();
    _inspect.animateWith(
      SpringSimulation(_snapSpring, _inspect.value, 1, 0),
    );
  }

  void _onInspectMove(LongPressMoveUpdateDetails details) {
    if (!_inspecting) return;
    _setFocus(_indexAt(details.localPosition.dy));
  }

  void _onInspectEnd() {
    if (!_inspecting) return;
    setState(() {
      _inspecting = false;
      _lingering = true;
    });
    if (_inspect.value < 0.95) {
      _inspect.animateWith(
        SpringSimulation(_snapSpring, _inspect.value, 1, 0),
      );
    }
    _lingerTimer?.cancel();
    _float
      ..duration = _ballotDuration
      ..value = 0
      ..repeat(reverse: true);
    _lingerTimer = Timer(_inspectLinger, _dismissInspect);
  }

  void _onInspectTap(int index) {
    if (_inspecting) return;
    if (_lingering || _inspect.value > 0.2) {
      if (index < _frontIndex) _bringToFront(index);
      _dismissInspect();
      return;
    }
    if (_flying || _slide.value.abs() > 8) return;
    if (index == _frontIndex) {
      widget.onTapCard(_cards[index]);
    } else {
      _bringToFront(index);
    }
  }

  void _setFocus(double next, {bool snap = false}) {
    final clamped = next.clamp(0.0, _frontIndex.toDouble());
    final value = snap ? clamped : _focus + (clamped - _focus) * 0.55;
    final tick = value.round();
    if (_lastFocusTick >= 0 && tick != _lastFocusTick) {
      HapticFeedback.selectionClick();
    }
    _lastFocusTick = tick;
    if ((value - _focus).abs() < 0.004) return;
    setState(() => _focus = value);
  }

  /// Center of each peek band = that card, so the thumb keeps the right one
  /// while focus still eases toward the neighbor as you slide.
  double _indexAt(double y) {
    final n = _cards.length;
    if (n <= 1) return 0;
    final tops = _restTops();
    if (y <= tops.first) return 0;
    for (var i = 0; i < n - 1; i++) {
      final start = tops[i];
      final end = tops[i + 1];
      if (y < end) {
        final span = (end - start).clamp(1.0, 400.0);
        final t = ((y - start) / span).clamp(0.0, 1.0);
        return i + (t - 0.5);
      }
    }
    return (n - 1).toDouble();
  }

  double _intensity(int index) {
    final amount = _inspect.value;
    final dist = (index - _focus).abs();
    final falloff = math.max(0.0, 1.0 - dist / _inspectFalloff);
    return amount * falloff;
  }

  double _restPeekOf(int index) {
    if (index >= _frontIndex) return LoyaltyWalletStack.fullHeight;
    return LoyaltyWalletStack.peekForDepth(_cards.length - index - 1);
  }

  double _extraFor(int revealed) {
    final intensity = _intensity(revealed);
    if (intensity <= 0) return 0;
    final need = math.max(0.0, _inspectPeek - _restPeekOf(revealed));
    return intensity * (need + 12);
  }

  List<double> _restTops() {
    final n = _cards.length;
    final tops = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      tops[i] = tops[i - 1] + LoyaltyWalletStack.peekForDepth(n - i);
    }
    return tops;
  }

  List<double> _cardTops() {
    final n = _cards.length;
    final tops = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      tops[i] = tops[i - 1] +
          LoyaltyWalletStack.peekForDepth(n - i) +
          _extraFor(i - 1);
    }
    return tops;
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_cards.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              context.l10n.walletHint,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return AnimatedBuilder(
              animation: Listenable.merge([_inspect, _float]),
              builder: (context, _) {
                final liveTops = _cardTops();
                final height = (liveTops.isEmpty ? 0.0 : liveTops.last) +
                    LoyaltyWalletStack.fullHeight +
                    24;
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: _onInspectStart,
                  onLongPressMoveUpdate: _onInspectMove,
                  onLongPressEnd: (_) => _onInspectEnd(),
                  onLongPressCancel: _dismissInspect,
                  child: SizedBox(
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < _cards.length; i++)
                          _WalletCardLayer(
                            key: ValueKey(_cards[i].id),
                            card: _cards[i],
                            isFront: i == _frontIndex,
                            top: liveTops[i],
                            slide: i == _frontIndex ? _slide : null,
                            width: _width,
                            flying: _flying,
                            instant: _inspectLive,
                            inspect: _intensity(i),
                            float: _floatWave,
                            onTap: () => _onInspectTap(i),
                            onHorizontalDragUpdate:
                                i == _frontIndex ? _onDragUpdate : null,
                            onHorizontalDragEnd:
                                i == _frontIndex ? _onDragEnd : null,
                            onHorizontalDragCancel:
                                i == _frontIndex ? _onDragCancel : null,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _WalletCardLayer extends StatelessWidget {
  const _WalletCardLayer({
    super.key,
    required this.card,
    required this.isFront,
    required this.top,
    required this.slide,
    required this.width,
    required this.flying,
    this.instant = false,
    this.inspect = 0,
    this.float = 0,
    required this.onTap,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
  });

  final LoyaltyCard card;
  final bool isFront;
  final double top;
  final Animation<double>? slide;
  final double width;
  final bool flying;
  final bool instant;
  final double inspect;
  final double float;
  final VoidCallback onTap;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final VoidCallback? onHorizontalDragCancel;

  @override
  Widget build(BuildContext context) {
    final shapes = context.tabbyShapes;
    final face = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shapes.radiusExtraLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isFront || inspect > 0.2 ? 0.22 : 0.12,
            ),
            blurRadius: isFront ? 22 : 14 + inspect * 10,
            offset: Offset(0, (isFront ? 10 : 5) - inspect * 4),
          ),
        ],
      ),
      child: LoyaltyCardFace(
        card: card,
        height: LoyaltyWalletStack.fullHeight,
        enableHero: isFront && !flying && inspect < 0.2,
        onTap: onTap,
      ),
    );

    Widget child = face;
    if (slide != null) {
      child = AnimatedBuilder(
        animation: slide!,
        builder: (context, visual) {
          final dx = slide!.value;
          final progress = width <= 0 ? 0.0 : dx / width;
          return Transform.translate(
            offset: Offset(dx, -dx.abs() * 0.06),
            child: Transform.rotate(
              angle: progress * _LoyaltyWalletStackState._maxTilt,
              alignment: Alignment.center,
              child: visual,
            ),
          );
        },
        child: face,
      );
    }

    if (inspect.abs() > 0.001) {
      final bob = inspect * float;
      child = Transform(
        alignment: const Alignment(0.95, 0.65),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0008)
          ..translateByDouble(0, -bob * 0.4, 0, 1)
          ..rotateX(0.04 * inspect + bob * 0.0015)
          ..rotateY(-0.12 * inspect)
          ..rotateZ(0.18 * inspect + bob * 0.002),
        child: child,
      );
    }

    if (onHorizontalDragUpdate != null) {
      child = GestureDetector(
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragEnd: onHorizontalDragEnd,
        onHorizontalDragCancel: onHorizontalDragCancel,
        child: child,
      );
    }

    if (instant) {
      return Positioned(top: top, left: 0, right: 0, child: child);
    }
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      top: top,
      left: 0,
      right: 0,
      child: child,
    );
  }
}
