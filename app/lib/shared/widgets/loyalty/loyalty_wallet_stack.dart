import 'package:flutter/physics.dart';
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
    required this.onLongPressCard,
    required this.onReorder,
  });

  final List<LoyaltyCard> cards;
  final void Function(LoyaltyCard card) onTapCard;
  final void Function(LoyaltyCard card) onLongPressCard;
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
    with SingleTickerProviderStateMixin {
  static const _flyExtent = 1.4;
  static const _commitFraction = 0.28;
  static const _commitVelocity = 800.0;
  static const _maxTilt = 0.18;

  static final _snapSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.82,
  );

  late final AnimationController _slide;
  double _width = 0;
  bool _flying = false;

  List<LoyaltyCard> get _cards => widget.cards;
  int get _frontIndex => _cards.length - 1;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_flying || _cards.length < 2) return;
    _slide.stop();
    _slide.value += details.delta.dx;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_flying || _cards.length < 2) return;
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
    if (_flying || _cards.length < 2) return;
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

  List<double> _cardTops() {
    final n = _cards.length;
    final tops = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      tops[i] = tops[i - 1] + LoyaltyWalletStack.peekForDepth(n - i);
    }
    return tops;
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final tops = _cardTops();
    final stackHeight =
        (tops.isEmpty ? 0.0 : tops.last) + LoyaltyWalletStack.fullHeight + 24;

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
            return SizedBox(
              height: stackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < _cards.length; i++)
                    _WalletCardLayer(
                      key: ValueKey(_cards[i].id),
                      card: _cards[i],
                      isFront: i == _frontIndex,
                      top: tops[i],
                      slide: i == _frontIndex ? _slide : null,
                      width: _width,
                      flying: _flying,
                      onTap: () {
                        if (i == _frontIndex) {
                          if (_flying || _slide.value.abs() > 8) return;
                          widget.onTapCard(_cards[i]);
                        } else {
                          _bringToFront(i);
                        }
                      },
                      onLongPress: () => widget.onLongPressCard(_cards[i]),
                      onHorizontalDragUpdate:
                          i == _frontIndex ? _onDragUpdate : null,
                      onHorizontalDragEnd: i == _frontIndex ? _onDragEnd : null,
                      onHorizontalDragCancel:
                          i == _frontIndex ? _onDragCancel : null,
                    ),
                ],
              ),
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
    required this.onTap,
    required this.onLongPress,
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
  final VoidCallback onTap;
  final VoidCallback onLongPress;
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
            color: Colors.black.withValues(alpha: isFront ? 0.22 : 0.12),
            blurRadius: isFront ? 22 : 14,
            offset: Offset(0, isFront ? 10 : 5),
          ),
        ],
      ),
      child: LoyaltyCardFace(
        card: card,
        height: LoyaltyWalletStack.fullHeight,
        enableHero: isFront && !flying,
        onTap: onTap,
        onLongPress: onLongPress,
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

    if (onHorizontalDragUpdate != null) {
      child = GestureDetector(
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragEnd: onHorizontalDragEnd,
        onHorizontalDragCancel: onHorizontalDragCancel,
        child: child,
      );
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
