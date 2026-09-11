import 'package:flutter/material.dart';

import '../../shared/models/budget.dart';
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

// ─── Couleurs sémantiques & accents Expressive ─────────────────────────────────

/// Tokens métier + accents saturés M3 Expressive (violet, lime, rose, jaune).
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
    required this.expressiveViolet,
    required this.expressiveLime,
    required this.expressivePink,
    required this.expressiveYellow,
    required this.expressiveVioletContainer,
    required this.expressiveLimeContainer,
    required this.expressivePinkContainer,
    required this.expressiveYellowContainer,
    required this.categoryPalette,
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

  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Accents saturés pour actions prioritaires et badges expressifs.
  final Color expressiveViolet;
  final Color expressiveLime;
  final Color expressivePink;
  final Color expressiveYellow;

  final Color expressiveVioletContainer;
  final Color expressiveLimeContainer;
  final Color expressivePinkContainer;
  final Color expressiveYellowContainer;

  final List<Color> categoryPalette;
  final List<Color> avatarPalette;

  static TabbySemanticColors light = TabbySemanticColors(
    success: AppColors.success,
    onSuccess: AppColors.onSuccessLight,
    successContainer: AppColors.successContainerLight,
    onSuccessContainer: AppColors.onSuccessContainerLight,
    warning: AppColors.warning,
    onWarning: AppColors.onWarningLight,
    warningContainer: AppColors.warningContainerLight,
    onWarningContainer: AppColors.onWarningContainerLight,
    danger: AppColors.danger,
    onDanger: AppColors.onDangerLight,
    dangerContainer: AppColors.dangerContainerLight,
    onDangerContainer: AppColors.onDangerContainerLight,
    expressiveViolet: AppColors.expressiveViolet,
    expressiveLime: AppColors.expressiveLime,
    expressivePink: AppColors.expressivePink,
    expressiveYellow: AppColors.expressiveYellow,
    expressiveVioletContainer: AppColors.expressiveVioletContainerLight,
    expressiveLimeContainer: AppColors.expressiveLimeContainerLight,
    expressivePinkContainer: AppColors.expressivePinkContainerLight,
    expressiveYellowContainer: AppColors.expressiveYellowContainerLight,
    categoryPalette: AppColors.categoryPalette,
    avatarPalette: AppColors.avatarPalette,
  );

  static TabbySemanticColors dark = TabbySemanticColors(
    success: AppColors.successDark,
    onSuccess: AppColors.onSuccessDark,
    successContainer: AppColors.successContainerDark,
    onSuccessContainer: AppColors.onSuccessContainerDark,
    warning: AppColors.warningDark,
    onWarning: AppColors.onWarningDark,
    warningContainer: AppColors.warningContainerDark,
    onWarningContainer: AppColors.onWarningContainerDark,
    danger: AppColors.dangerDark,
    onDanger: AppColors.onDangerDark,
    dangerContainer: AppColors.dangerContainerDark,
    onDangerContainer: AppColors.onDangerContainerDark,
    expressiveViolet: AppColors.expressiveVioletDark,
    expressiveLime: AppColors.expressiveLimeDark,
    expressivePink: AppColors.expressivePinkDark,
    expressiveYellow: AppColors.expressiveYellowDark,
    expressiveVioletContainer: AppColors.expressiveVioletContainerDark,
    expressiveLimeContainer: AppColors.expressiveLimeContainerDark,
    expressivePinkContainer: AppColors.expressivePinkContainerDark,
    expressiveYellowContainer: AppColors.expressiveYellowContainerDark,
    categoryPalette: AppColors.categoryPalette,
    avatarPalette: AppColors.avatarPalette,
  );

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
    Color? expressiveViolet,
    Color? expressiveLime,
    Color? expressivePink,
    Color? expressiveYellow,
    Color? expressiveVioletContainer,
    Color? expressiveLimeContainer,
    Color? expressivePinkContainer,
    Color? expressiveYellowContainer,
    List<Color>? categoryPalette,
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
      expressiveViolet: expressiveViolet ?? this.expressiveViolet,
      expressiveLime: expressiveLime ?? this.expressiveLime,
      expressivePink: expressivePink ?? this.expressivePink,
      expressiveYellow: expressiveYellow ?? this.expressiveYellow,
      expressiveVioletContainer:
          expressiveVioletContainer ?? this.expressiveVioletContainer,
      expressiveLimeContainer:
          expressiveLimeContainer ?? this.expressiveLimeContainer,
      expressivePinkContainer:
          expressivePinkContainer ?? this.expressivePinkContainer,
      expressiveYellowContainer:
          expressiveYellowContainer ?? this.expressiveYellowContainer,
      categoryPalette: categoryPalette ?? this.categoryPalette,
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
      onSuccessContainer:
          lerpC(onSuccessContainer, other.onSuccessContainer),
      warning: lerpC(warning, other.warning),
      onWarning: lerpC(onWarning, other.onWarning),
      warningContainer: lerpC(warningContainer, other.warningContainer),
      onWarningContainer:
          lerpC(onWarningContainer, other.onWarningContainer),
      danger: lerpC(danger, other.danger),
      onDanger: lerpC(onDanger, other.onDanger),
      dangerContainer: lerpC(dangerContainer, other.dangerContainer),
      onDangerContainer: lerpC(onDangerContainer, other.onDangerContainer),
      expressiveViolet: lerpC(expressiveViolet, other.expressiveViolet),
      expressiveLime: lerpC(expressiveLime, other.expressiveLime),
      expressivePink: lerpC(expressivePink, other.expressivePink),
      expressiveYellow: lerpC(expressiveYellow, other.expressiveYellow),
      expressiveVioletContainer:
          lerpC(expressiveVioletContainer, other.expressiveVioletContainer),
      expressiveLimeContainer:
          lerpC(expressiveLimeContainer, other.expressiveLimeContainer),
      expressivePinkContainer:
          lerpC(expressivePinkContainer, other.expressivePinkContainer),
      expressiveYellowContainer:
          lerpC(expressiveYellowContainer, other.expressiveYellowContainer),
      categoryPalette: t < 0.5 ? categoryPalette : other.categoryPalette,
      avatarPalette: t < 0.5 ? avatarPalette : other.avatarPalette,
    );
  }
}
