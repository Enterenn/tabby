import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../models/loyalty_card.dart';
import 'loyalty_card_face.dart';

/// Pile wallet interactive — tape une carte pour la mettre devant, swipe pour parcourir.
class LoyaltyWalletStack extends StatelessWidget {
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

  static const _peek = 72.0;
  static const _sideStep = 10.0;
  static const _fullHeight = LoyaltyCardLayout.cardHeight;

  int get _frontIndex => cards.length - 1;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final stackHeight = _fullHeight + (cards.length - 1) * _peek;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cards.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              context.l10n.walletHint,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < cards.length; i++)
                _WalletCardLayer(
                  key: ValueKey(cards[i].id),
                  card: cards[i],
                  depth: _frontIndex - i,
                  isFront: i == _frontIndex,
                  top: i * _peek,
                  horizontalInset: (_frontIndex - i) * _sideStep,
                  scale: 1 - (_frontIndex - i) * 0.025,
                  onTap: () {
                    if (i == _frontIndex) {
                      onTapCard(cards[i]);
                    } else {
                      _bringToFront(i);
                    }
                  },
                  onLongPress: () => onLongPressCard(cards[i]),
                  onHorizontalDragEnd: i == _frontIndex && cards.length > 1
                      ? (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v < -200) {
                            _cycleNext();
                          } else if (v > 200) {
                            _cyclePrevious();
                          }
                        }
                      : null,
                ),
            ],
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 16),
          _WalletDots(count: cards.length, activeIndex: _frontIndex),
        ],
      ],
    );
  }

  void _bringToFront(int index) {
    if (index < 0 || index >= cards.length - 1) return;
    final list = List<LoyaltyCard>.from(cards);
    final card = list.removeAt(index);
    list.add(card);
    onReorder(list);
  }

  void _cycleNext() {
    final list = List<LoyaltyCard>.from(cards);
    final front = list.removeLast();
    list.insert(0, front);
    onReorder(list);
  }

  void _cyclePrevious() {
    final list = List<LoyaltyCard>.from(cards);
    final back = list.removeAt(0);
    list.add(back);
    onReorder(list);
  }
}

class _WalletCardLayer extends StatelessWidget {
  const _WalletCardLayer({
    super.key,
    required this.card,
    required this.depth,
    required this.isFront,
    required this.top,
    required this.horizontalInset,
    required this.scale,
    required this.onTap,
    required this.onLongPress,
    this.onHorizontalDragEnd,
  });

  final LoyaltyCard card;
  final int depth;
  final bool isFront;
  final double top;
  final double horizontalInset;
  final double scale;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final GestureDragEndCallback? onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    final layer = AnimatedPositioned(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      top: top,
      left: horizontalInset,
      right: horizontalInset,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        scale: scale,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: LoyaltyCardFace(
            card: card,
            height: isFront
                ? LoyaltyWalletStack._fullHeight
                : LoyaltyWalletStack._peek + 36,
            compact: !isFront,
            enableHero: isFront,
            onTap: onTap,
            onLongPress: onLongPress,
            trailing: !isFront
                ? Icon(
                    Symbols.north_rounded,
                    size: 18,
                    color: card.brand.onPrimary.withValues(alpha: 0.65),
                    fill: 1,
                  )
                : null,
          ),
        ),
      ),
    );

    return layer;
  }
}

class _WalletDots extends StatelessWidget {
  const _WalletDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.outlineVariant,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
