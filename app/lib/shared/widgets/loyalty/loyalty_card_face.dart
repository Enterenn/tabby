import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/loyalty_brand.dart';
import '../../models/loyalty_card.dart';

/// Dimensions partagées — doivent correspondre au padding horizontal de
/// [CardsScreen] et [_CardFullScreen] pour un Hero pixel-perfect.
abstract final class LoyaltyCardLayout {
  static const double cardHeight = 168;
  static const double screenHorizontalInset = 16;

  static double cardWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - screenHorizontalInset * 2;
}

/// Carte de fidélité visuelle — dégradé marque, logo, nom.
class LoyaltyCardFace extends StatelessWidget {
  const LoyaltyCardFace({
    super.key,
    required this.card,
    this.height = LoyaltyCardLayout.cardHeight,
    this.compact = false,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.enableHero = false,
  });

  final LoyaltyCard card;
  final double height;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  /// Hero vers l'écran détail (désactivé pour les aperçus).
  final bool enableHero;

  LoyaltyBrand get _brand => card.brand;

  @override
  Widget build(BuildContext context) {
    final shapes = context.tabbyShapes;
    final brand = _brand;
    final fg = brand.onPrimary;

    final face = Material(
      color: Colors.transparent,
      elevation: compact ? 1 : 4,
      shadowColor: brand.primary.withValues(alpha: 0.45),
      shape: shapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          height: compact ? 72 : height,
          decoration: BoxDecoration(gradient: brand.gradient),
          child: Stack(
            children: [
              // Motif décoratif
              Positioned(
                right: -24,
                top: -24,
                child: Icon(
                  Symbols.contactless_rounded,
                  size: compact ? 80 : 140,
                  color: fg.withValues(alpha: 0.07),
                  fill: 1,
                ),
              ),
              Positioned(
                left: compact ? 14 : 20,
                right: compact ? 14 : 20,
                top: compact ? 12 : 18,
                bottom: compact ? 12 : 18,
                child: Row(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    _BrandLogo(brand: brand, size: compact ? 40 : 52),
                    SizedBox(width: compact ? 12 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: compact
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          Text(
                            brand.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Carte de fidélité',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: fg.withValues(alpha: 0.78),
                                  ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  card.isBarcode
                                      ? Symbols.barcode_rounded
                                      : Symbols.qr_code_2_rounded,
                                  size: 16,
                                  color: fg.withValues(alpha: 0.85),
                                  fill: 1,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  card.isBarcode
                                      ? 'Code-barres'
                                      : 'QR Code',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: fg.withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                Icon(
                                  Symbols.contactless_rounded,
                                  size: 22,
                                  color: fg.withValues(alpha: 0.55),
                                  fill: 1,
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              card.isBarcode ? 'Code-barres' : 'QR Code',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: fg.withValues(alpha: 0.75),
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!enableHero) return face;

    final heroSize = SizedBox(
      width: LoyaltyCardLayout.cardWidth(context),
      height: compact ? 72 : height,
      child: face,
    );

    return Hero(
      tag: card.heroTag,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        return SizedBox(
          width: LoyaltyCardLayout.cardWidth(flightContext),
          height: height,
          child: Material(
            color: Colors.transparent,
            child: LoyaltyCardFace(
              card: card,
              height: height,
              compact: compact,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: heroSize,
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand, required this.size});

  final LoyaltyBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = brand.onPrimary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Center(
        child: brand.logoAsset != null
            ? SvgPicture.asset(
                brand.logoAsset!,
                width: size * 0.62,
                height: size * 0.62,
                fit: BoxFit.contain,
              )
            : brand.monogram.isEmpty
                ? Icon(Symbols.storefront_rounded,
                    color: fg, size: size * 0.45, fill: 1)
                : Text(
                    brand.monogram,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: size * 0.38,
                      height: 1,
                    ),
                  ),
      ),
    );
  }
}

/// Pile wallet — cartes empilées avec en-têtes visibles.
class LoyaltyWalletStack extends StatelessWidget {
  const LoyaltyWalletStack({
    super.key,
    required this.cards,
    required this.onTapCard,
    required this.onLongPressCard,
  });

  final List<LoyaltyCard> cards;
  final void Function(LoyaltyCard card) onTapCard;
  final void Function(LoyaltyCard card) onLongPressCard;

  static const _peek = 52.0;
  static const _fullHeight = LoyaltyCardLayout.cardHeight;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final stackHeight = _fullHeight + (cards.length - 1) * _peek;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < cards.length; i++)
            Positioned(
              top: i * _peek,
              left: 0,
              right: 0,
              child: LoyaltyCardFace(
                card: cards[i],
                height: i == cards.length - 1 ? _fullHeight : _peek + 28,
                compact: i != cards.length - 1,
                enableHero: true,
                onTap: () => onTapCard(cards[i]),
                onLongPress: () => onLongPressCard(cards[i]),
              ),
            ),
        ],
      ),
    );
  }
}
