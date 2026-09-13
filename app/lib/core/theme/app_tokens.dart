import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/models/budget.dart';
import '../../shared/models/category.dart';
import 'app_colors.dart';

// ─── Accès contextuel ───────────────────────────────────────────────────────

extension BudgetStatusX on Budget {
  Color statusColor(TabbySemanticColors semantic) => switch (status) {
        BudgetStatus.ok => semantic.success,
        BudgetStatus.warning => semantic.warning,
        BudgetStatus.danger => semantic.danger,
      };
}

extension TabbyThemeContext on BuildContext {
  ColorScheme get tabbyColors => Theme.of(this).colorScheme;

  TabbyShapeTokens get tabbyShapes =>
      Theme.of(this).extension<TabbyShapeTokens>()!;

  TabbyTypographyTokens get tabbyType =>
      Theme.of(this).extension<TabbyTypographyTokens>()!;

  TabbySemanticColors get tabbySemantic =>
      Theme.of(this).extension<TabbySemanticColors>()!;

  TabbySpaceTokens get tabbySpace =>
      Theme.of(this).extension<TabbySpaceTokens>()!;

  /// Hauteur réelle de la navbar flottante, inset système compris.
  /// Aligné sur [MainScaffold] : pad 20+16, barre 72.
  double get tabBarClearance {
    const chrome = 20.0 + 72.0 + 16.0;
    return chrome + MediaQuery.viewPaddingOf(this).bottom;
  }
}

// ─── Espacement ──────────────────────────────────────────────────────────────

/// Échelle 4 · 8 · 12 · 16 · 20 · 24 · 28.
@immutable
class TabbySpaceTokens extends ThemeExtension<TabbySpaceTokens> {
  const TabbySpaceTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  static const TabbySpaceTokens standard = TabbySpaceTokens(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 24,
    xxxl: 28,
  );

  EdgeInsets get gutter => EdgeInsets.symmetric(horizontal: lg);
  EdgeInsets get gutterWide => EdgeInsets.symmetric(horizontal: xxl);
  EdgeInsets get gutterAuth => EdgeInsets.symmetric(horizontal: xxxl);

  @override
  TabbySpaceTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  }) {
    return TabbySpaceTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  TabbySpaceTokens lerp(ThemeExtension<TabbySpaceTokens>? other, double t) {
    if (other is! TabbySpaceTokens) return this;
    double lerpD(double a, double b) => a + (b - a) * t;
    return TabbySpaceTokens(
      xs: lerpD(xs, other.xs),
      sm: lerpD(sm, other.sm),
      md: lerpD(md, other.md),
      lg: lerpD(lg, other.lg),
      xl: lerpD(xl, other.xl),
      xxl: lerpD(xxl, other.xxl),
      xxxl: lerpD(xxxl, other.xxxl),
    );
  }
}

// ─── Shapes M3 Expressive ─────────────────────────────────────────────────────

/// Tokens de forme M3 Expressive — coins arrondis + cercles / pills.
///
/// Réf. corner scale : xs 4 · sm 8 · md 12 · lg 16 · xl 28 · full pill
@immutable
class TabbyShapeTokens extends ThemeExtension<TabbyShapeTokens> {
  const TabbyShapeTokens({
    required this.cornerExtraSmall,
    required this.cornerSmall,
    required this.cornerMedium,
    required this.cornerLarge,
    required this.cornerExtraLarge,
    required this.cornerFull,
  });

  final double cornerExtraSmall;
  final double cornerSmall;
  final double cornerMedium;
  final double cornerLarge;
  final double cornerExtraLarge;
  final double cornerFull;

  static const TabbyShapeTokens standard = TabbyShapeTokens(
    cornerExtraSmall: 4,
    cornerSmall: 8,
    cornerMedium: 12,
    cornerLarge: 16,
    cornerExtraLarge: 28,
    cornerFull: 999,
  );

  BorderRadius get radiusExtraSmall => BorderRadius.circular(cornerExtraSmall);
  BorderRadius get radiusSmall => BorderRadius.circular(cornerSmall);
  BorderRadius get radiusMedium => BorderRadius.circular(cornerMedium);
  BorderRadius get radiusLarge => BorderRadius.circular(cornerLarge);
  BorderRadius get radiusExtraLarge => BorderRadius.circular(cornerExtraLarge);
  BorderRadius get radiusFull => BorderRadius.circular(cornerFull);

  /// Cartes, dialogs, bottom sheets — 28 dp.
  RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: radiusExtraLarge);

  /// Boutons CTA — pill fully rounded.
  RoundedRectangleBorder get buttonShape =>
      RoundedRectangleBorder(borderRadius: radiusFull);

  /// Inputs, list tiles — 16 dp.
  RoundedRectangleBorder get fieldShape =>
      RoundedRectangleBorder(borderRadius: radiusLarge);

  /// Modales — coins supérieurs 28 dp.
  RoundedRectangleBorder get modalTopShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(cornerExtraLarge),
        ),
      );

  /// Cercle — avatars, FAB, icônes d'action.
  CircleBorder circle({BorderSide side = BorderSide.none}) =>
      CircleBorder(side: side);

  /// Pill — badges texte.
  StadiumBorder pill({BorderSide side = BorderSide.none}) =>
      StadiumBorder(side: side);

  @override
  TabbyShapeTokens copyWith({
    double? cornerExtraSmall,
    double? cornerSmall,
    double? cornerMedium,
    double? cornerLarge,
    double? cornerExtraLarge,
    double? cornerFull,
  }) {
    return TabbyShapeTokens(
      cornerExtraSmall: cornerExtraSmall ?? this.cornerExtraSmall,
      cornerSmall: cornerSmall ?? this.cornerSmall,
      cornerMedium: cornerMedium ?? this.cornerMedium,
      cornerLarge: cornerLarge ?? this.cornerLarge,
      cornerExtraLarge: cornerExtraLarge ?? this.cornerExtraLarge,
      cornerFull: cornerFull ?? this.cornerFull,
    );
  }

  @override
  TabbyShapeTokens lerp(ThemeExtension<TabbyShapeTokens>? other, double t) {
    if (other is! TabbyShapeTokens) return this;
    double lerpD(double a, double b) => a + (b - a) * t;
    return TabbyShapeTokens(
      cornerExtraSmall:
          lerpD(cornerExtraSmall, other.cornerExtraSmall),
      cornerSmall: lerpD(cornerSmall, other.cornerSmall),
      cornerMedium: lerpD(cornerMedium, other.cornerMedium),
      cornerLarge: lerpD(cornerLarge, other.cornerLarge),
      cornerExtraLarge:
          lerpD(cornerExtraLarge, other.cornerExtraLarge),
      cornerFull: lerpD(cornerFull, other.cornerFull),
    );
  }
}

// ─── Typographie M3 Expressive ────────────────────────────────────────────────

/// Échelle typographique : lecture nette (ROND 0) + chiffres clés condensés.
@immutable
class TabbyTypographyTokens extends ThemeExtension<TabbyTypographyTokens> {
  const TabbyTypographyTokens({
    required this.figureHero,
    required this.figureLarge,
    required this.figureMedium,
    required this.figureSmall,
    required this.displayEditorial,
    required this.clockDisplay,
  });

  /// Solde principal, montant budget hero — ex. « 36,50 € ».
  final TextStyle figureHero;

  /// Montants secondaires, totaux de section.
  final TextStyle figureLarge;

  /// Montants inline, KPI cards.
  final TextStyle figureMedium;

  /// Petits montants, deltas.
  final TextStyle figureSmall;

  /// Titres éditoriaux expressifs (écrans d'accueil, empty states).
  final TextStyle displayEditorial;

  /// Affichage horloge / compteur (haute, condensée).
  final TextStyle clockDisplay;

  /// Google Sans Flex — axe variable wght / ROND / GRAD / opsz.
  static TextStyle flex({
    required double fontSize,
    required double wght,
    double rond = 0,
    double grad = 0,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'GoogleSansFlex',
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontVariations: [
        FontVariation('wght', wght),
        FontVariation('ROND', rond),
        FontVariation('GRAD', grad),
        FontVariation('opsz', fontSize.clamp(8, 144)),
      ],
    );
  }

  static TabbyTypographyTokens create({
    required ColorScheme scheme,
    required double grad,
  }) {
    TextStyle figure({
      required double size,
      required double line,
      required double wght,
      required double tracking,
    }) {
      return flex(
        fontSize: size,
        wght: wght,
        rond: 0,
        grad: grad + 50,
        height: line / size,
        letterSpacing: tracking,
        color: scheme.onSurface,
      );
    }

    return TabbyTypographyTokens(
      figureHero: figure(
        size: 52,
        line: 56,
        wght: 900,
        tracking: -2.5,
      ),
      figureLarge: figure(
        size: 40,
        line: 44,
        wght: 850,
        tracking: -2.0,
      ),
      figureMedium: figure(
        size: 32,
        line: 36,
        wght: 800,
        tracking: -1.5,
      ),
      figureSmall: figure(
        size: 24,
        line: 28,
        wght: 750,
        tracking: -1.0,
      ),
      displayEditorial: flex(
        fontSize: 36,
        wght: 800,
        rond: 0,
        grad: grad + 30,
        height: 44 / 36,
        letterSpacing: -1.2,
        color: scheme.onSurface,
      ),
      clockDisplay: flex(
        fontSize: 64,
        wght: 900,
        rond: 0,
        grad: grad + 80,
        height: 68 / 64,
        letterSpacing: -3.0,
        color: scheme.onSurface,
      ),
    );
  }

  /// Construit l'échelle M3 standard (15 rôles) — lecture ROND 0.
  static TextTheme buildTextTheme({
    required ColorScheme scheme,
    required double grad,
  }) {
    TextStyle role({
      required double size,
      required double line,
      required double wght,
      double rond = 0,
      double tracking = 0,
      Color? color,
    }) {
      return flex(
        fontSize: size,
        wght: wght,
        rond: rond,
        grad: grad,
        height: line / size,
        letterSpacing: tracking,
        color: color ?? scheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge: role(
        size: 57, line: 64, wght: 800, tracking: -1.5,
      ),
      displayMedium: role(
        size: 45, line: 52, wght: 800, tracking: -1.2,
      ),
      displaySmall: role(
        size: 36, line: 44, wght: 750, tracking: -1.0,
      ),
      headlineLarge: role(
        size: 32, line: 40, wght: 700, rond: 20, tracking: -0.5,
      ),
      headlineMedium: role(
        size: 28, line: 36, wght: 700, rond: 15, tracking: -0.25,
      ),
      headlineSmall: role(
        size: 24, line: 32, wght: 650, rond: 10,
      ),
      titleLarge: role(
        size: 22, line: 28, wght: 600, rond: 0, tracking: 0,
      ),
      titleMedium: role(
        size: 16, line: 24, wght: 600, rond: 0, tracking: 0.15,
      ),
      titleSmall: role(
        size: 14, line: 20, wght: 600, rond: 0, tracking: 0.1,
      ),
      bodyLarge: role(
        size: 16, line: 24, wght: 400, rond: 0, tracking: 0.5,
      ),
      bodyMedium: role(
        size: 14, line: 20, wght: 400, rond: 0, tracking: 0.25,
      ),
      bodySmall: role(
        size: 12, line: 16, wght: 400, rond: 0, tracking: 0.4,
      ),
      labelLarge: role(
        size: 14, line: 20, wght: 600, rond: 0, tracking: 0.1,
      ),
      labelMedium: role(
        size: 12, line: 16, wght: 600, rond: 0, tracking: 0.5,
      ),
      labelSmall: role(
        size: 11, line: 16, wght: 600, rond: 0, tracking: 0.5,
      ),
    );
  }

  @override
  TabbyTypographyTokens copyWith({
    TextStyle? figureHero,
    TextStyle? figureLarge,
    TextStyle? figureMedium,
    TextStyle? figureSmall,
    TextStyle? displayEditorial,
    TextStyle? clockDisplay,
  }) {
    return TabbyTypographyTokens(
      figureHero: figureHero ?? this.figureHero,
      figureLarge: figureLarge ?? this.figureLarge,
      figureMedium: figureMedium ?? this.figureMedium,
      figureSmall: figureSmall ?? this.figureSmall,
      displayEditorial: displayEditorial ?? this.displayEditorial,
      clockDisplay: clockDisplay ?? this.clockDisplay,
    );
  }

  @override
  TabbyTypographyTokens lerp(
    ThemeExtension<TabbyTypographyTokens>? other,
    double t,
  ) {
    if (other is! TabbyTypographyTokens) return this;
    return TabbyTypographyTokens(
      figureHero: TextStyle.lerp(figureHero, other.figureHero, t)!,
      figureLarge: TextStyle.lerp(figureLarge, other.figureLarge, t)!,
      figureMedium: TextStyle.lerp(figureMedium, other.figureMedium, t)!,
      figureSmall: TextStyle.lerp(figureSmall, other.figureSmall, t)!,
      displayEditorial:
          TextStyle.lerp(displayEditorial, other.displayEditorial, t)!,
      clockDisplay: TextStyle.lerp(clockDisplay, other.clockDisplay, t)!,
    );
  }
}

Color _harmonizeWith(Color from, Color to) {
  if (from == to) return from;
  return Color(Blend.harmonize(from.toARGB32(), to.toARGB32()));
}

// ─── Couleurs sémantiques métier ──────────────────────────────────────────────

/// Success / warning + palettes dérivées du [ColorScheme].
///
/// `danger*` est un alias de `ColorScheme.error*` (pas une teinte parallèle).
/// Les couleurs de marques fidélité restent dans [LoyaltyBrand] ; le fallback
/// hors catalogue est [brandFallback] (`secondary`).
@immutable
class TabbySemanticColors extends ThemeExtension<TabbySemanticColors> {
  const TabbySemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.brandFallback,
    required this.categoryPalette,
    required this.chartPalette,
    required this.avatarPalette,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Alias de [ColorScheme.error].
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Fallback cartes fidélité hors catalogue — [ColorScheme.primary].
  final Color brandFallback;

  final List<Color> categoryPalette;
  final List<Color> chartPalette;
  final List<Color> avatarPalette;

  factory TabbySemanticColors.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    Color hue(Color color) => _harmonizeWith(color, scheme.primary);
    return TabbySemanticColors(
      success: hue(isDark ? AppColors.successDark : AppColors.success),
      onSuccess: hue(isDark ? AppColors.onSuccessDark : AppColors.onSuccessLight),
      successContainer: hue(isDark
          ? AppColors.successContainerDark
          : AppColors.successContainerLight),
      onSuccessContainer: hue(isDark
          ? AppColors.onSuccessContainerDark
          : AppColors.onSuccessContainerLight),
      warning: hue(isDark ? AppColors.warningDark : AppColors.warning),
      onWarning: hue(isDark ? AppColors.onWarningDark : AppColors.onWarningLight),
      warningContainer: hue(isDark
          ? AppColors.warningContainerDark
          : AppColors.warningContainerLight),
      onWarningContainer: hue(isDark
          ? AppColors.onWarningContainerDark
          : AppColors.onWarningContainerLight),
      danger: scheme.error,
      onDanger: scheme.onError,
      dangerContainer: scheme.errorContainer,
      onDangerContainer: scheme.onErrorContainer,
      brandFallback: scheme.primary,
      categoryPalette: _paletteFrom(scheme),
      chartPalette: _paletteFrom(scheme),
      avatarPalette: [
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        scheme.primaryContainer,
        scheme.secondaryContainer,
      ],
    );
  }

  /// Pastilles saturées uniquement — pas de containers (icône = blanc ou noir).
  static List<Color> _paletteFrom(ColorScheme s) => [
        s.primary,
        s.secondary,
        s.error,
        const Color(0xFFE67E22),
        const Color(0xFF27AE60),
        const Color(0xFF2980B9),
        const Color(0xFF8E44AD),
        const Color(0xFF16A085),
        const Color(0xFF7F8C8D),
      ];

  /// Fond de pastille = hex de la catégorie (même couleur partout).
  Color chartColorFor(Category category) => category.resolvedColor;

  /// Icône / texte : blanc ou noir selon la luminance, jamais la même teinte.
  Color onFor(Color color, ColorScheme _) => contrastOn(color);

  static Color contrastOn(Color color) =>
      color.computeLuminance() > 0.55
          ? const Color(0xFF1C1B1F)
          : const Color(0xFFFFFFFF);

  /// Retourne la couleur de solde (+/-) selon le montant.
  Color balanceColor(double amount) {
    if (amount.abs() < 0.01) return onSuccessContainer;
    return amount > 0 ? success : danger;
  }

  @override
  TabbySemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? brandFallback,
    List<Color>? categoryPalette,
    List<Color>? chartPalette,
    List<Color>? avatarPalette,
  }) {
    return TabbySemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      brandFallback: brandFallback ?? this.brandFallback,
      categoryPalette: categoryPalette ?? this.categoryPalette,
      chartPalette: chartPalette ?? this.chartPalette,
      avatarPalette: avatarPalette ?? this.avatarPalette,
    );
  }

  @override
  TabbySemanticColors lerp(
    ThemeExtension<TabbySemanticColors>? other,
    double t,
  ) {
    if (other is! TabbySemanticColors) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    return TabbySemanticColors(
      success: lerpC(success, other.success),
      onSuccess: lerpC(onSuccess, other.onSuccess),
      successContainer: lerpC(successContainer, other.successContainer),
      onSuccessContainer: lerpC(onSuccessContainer, other.onSuccessContainer),
      warning: lerpC(warning, other.warning),
      onWarning: lerpC(onWarning, other.onWarning),
      warningContainer: lerpC(warningContainer, other.warningContainer),
      onWarningContainer: lerpC(onWarningContainer, other.onWarningContainer),
      danger: lerpC(danger, other.danger),
      onDanger: lerpC(onDanger, other.onDanger),
      dangerContainer: lerpC(dangerContainer, other.dangerContainer),
      onDangerContainer: lerpC(onDangerContainer, other.onDangerContainer),
      brandFallback: lerpC(brandFallback, other.brandFallback),
      categoryPalette: t < 0.5 ? categoryPalette : other.categoryPalette,
      chartPalette: t < 0.5 ? chartPalette : other.chartPalette,
      avatarPalette: t < 0.5 ? avatarPalette : other.avatarPalette,
    );
  }
}
