import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final shapes = context.tabbyShapes;
    final brand = card.brandFor(context.tabbySemantic.brandFallback);
    final fg = brand.onPrimary;

    final face = Material(
      color: Colors.transparent,
      elevation: 0,
      shape: shapes.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          height: height,
          decoration: BoxDecoration(gradient: brand.gradient),
          child: Stack(
            children: [
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.loyaltyCard,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: fg),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  card.isBarcode
                                      ? Symbols.barcode_rounded
                                      : Symbols.qr_code_2_rounded,
                                  size: 16,
                                  color: fg,
                                  fill: 1,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  card.isBarcode
                                      ? context.l10n.barcode
                                      : context.l10n.qrCode,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: fg,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                Icon(
                                  Symbols.contactless_rounded,
                                  size: 22,
                                  color: fg,
                                  fill: 1,
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              card.isBarcode
                                  ? context.l10n.barcode
                                  : context.l10n.qrCode,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(color: fg),
                            ),
                        ],
                      ),
                    ),
                    ?trailing,
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
      height: height,
      child: face,
    );

    return Hero(
      tag: card.heroTag,
      flightShuttleBuilder:
          (
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
      child: Material(color: Colors.transparent, child: heroSize),
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
        color: brand.secondary ?? brand.primary,
        shape: BoxShape.circle,
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
            ? Icon(
                Symbols.storefront_rounded,
                color: fg,
                size: size * 0.45,
                fill: 1,
              )
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
