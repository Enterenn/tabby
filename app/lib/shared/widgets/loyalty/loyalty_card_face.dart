import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../models/loyalty_brand.dart';
import '../../models/loyalty_brand_logos.dart';
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
              const Positioned.fill(
                child: IgnorePointer(child: _CardGrain()),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CardEdgePainter(
                      radius: shapes.cornerExtraLarge,
                      light: brand.edgeLight,
                      dark: brand.edgeDark,
                    ),
                  ),
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
                            card.brandName,
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

/// Trait 1 px sur tout le contour arrondi — clair en haut, plus sombre en bas.
class _CardEdgePainter extends CustomPainter {
  const _CardEdgePainter({
    required this.radius,
    required this.light,
    required this.dark,
  });

  final double radius;
  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    ).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, dark],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _CardEdgePainter old) =>
      old.radius != radius || old.light != light || old.dark != dark;
}

/// Grain tuilé, très léger — matière papier / plastique.
class _CardGrain extends StatefulWidget {
  const _CardGrain();

  @override
  State<_CardGrain> createState() => _CardGrainState();
}

class _CardGrainState extends State<_CardGrain> {
  static ui.Image? _tile;
  static Future<ui.Image>? _pending;

  static Future<ui.Image> _ensure() {
    final cached = _tile;
    if (cached != null) return Future.value(cached);
    return _pending ??= _renderTile().then((image) {
      _tile = image;
      return image;
    });
  }

  static Future<ui.Image> _renderTile() {
    const size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rng = math.Random(42);
    final paint = Paint()..isAntiAlias = false;
    for (var i = 0; i < 3200; i++) {
      paint.color = (rng.nextBool() ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
          .withValues(alpha: 0.55 + rng.nextDouble() * 0.45);
      canvas.drawRect(
        Rect.fromLTWH(rng.nextDouble() * size, rng.nextDouble() * size, 1, 1),
        paint,
      );
    }
    return recorder.endRecording().toImage(size, size);
  }

  @override
  void initState() {
    super.initState();
    if (_tile == null) {
      _ensure().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile;
    if (tile == null) return const SizedBox.shrink();
    return CustomPaint(painter: _GrainPainter(tile));
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter(this.tile);

  final ui.Image tile;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: tile,
      repeat: ImageRepeat.repeat,
      opacity: 0.06,
      blendMode: BlendMode.overlay,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
    );
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.tile != tile;
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand, required this.size});

  final LoyaltyBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = LoyaltyBrandLogos.assetFor(brand);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: brand.logoBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: logo != null
          ? logo.isSvg
              ? Padding(
                  padding: EdgeInsets.all(size * 0.18),
                  child: SvgPicture.asset(
                    logo.path,
                    fit: BoxFit.contain,
                  ),
                )
              : Image.asset(
                  logo.path,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => _Monogram(brand: brand, size: size),
                )
          : _Monogram(brand: brand, size: size),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.brand, required this.size});

  final LoyaltyBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = brand.onPrimary;
    if (brand.monogram.isEmpty) {
      return Icon(
        Symbols.storefront_rounded,
        color: fg,
        size: size * 0.45,
        fill: 1,
      );
    }
    return Center(
      child: Text(
        brand.monogram,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
          height: 1,
        ),
      ),
    );
  }
}
