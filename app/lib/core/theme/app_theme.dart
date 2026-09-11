import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// À appeler une seule fois dans main() avant runApp().
  static void configureSymbols() {
    MaterialSymbolsBase.setRoundedVariationDefaults(
      fill: 0,
      weight: 400,
      grade: 0,
      opticalSize: 24,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // GRAD: léger négatif en dark → réduit le poids visuel sans layout shift
    final grad = isDark ? -25.0 : 0.0;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: const Color(0xFF2E2A22),
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _buildTextTheme(grad, scheme),
      scaffoldBackgroundColor: scheme.surfaceContainerLow,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: scheme.primary,
        titleTextStyle: _gsf(
          fontSize: 22,
          wght: 800,
          rond: 80,
          grad: grad,
          color: scheme.onSurface,
        ),
      ),

      // Card filled M3 : fond surfaceContainerHighest, pas d'ombre
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: _gsf(fontSize: 16, wght: 700, rond: 40, grad: grad),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: _gsf(fontSize: 15, wght: 600, rond: 20, grad: grad),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: _gsf(fontSize: 14, wght: 600, rond: 0, grad: grad),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: _gsf(
          fontSize: 14,
          wght: 400,
          rond: 0,
          grad: grad,
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle:
            _gsf(fontSize: 12, wght: 500, rond: 0, grad: grad, color: scheme.primary),
      ),

      // NavigationBar M3 — Symbols filled quand sélectionné, outlined sinon
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onPrimaryContainer,
              fill: 1,
              weight: 600,
            );
          }
          return IconThemeData(
            color: scheme.onSurfaceVariant,
            fill: 0,
            weight: 400,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _gsf(
              fontSize: 11,
              wght: 700,
              rond: 20,
              grad: grad,
              color: scheme.onSurface,
            );
          }
          return _gsf(
            fontSize: 11,
            wght: 400,
            rond: 0,
            grad: grad,
            color: scheme.onSurfaceVariant,
          );
        }),
        elevation: 3,
        surfaceTintColor: scheme.primary,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: _gsf(
          fontSize: 14,
          wght: 400,
          rond: 0,
          grad: grad,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: _gsf(
          fontSize: 20,
          wght: 700,
          rond: 60,
          grad: grad,
          color: scheme.onSurface,
        ),
      ),

      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    );
  }

  /// Construit la type scale M3 complète avec Google Sans Flex.
  ///
  /// Stratégie des axes :
  /// - Display → ROND élevé (80–100) : expressif, impact visuel fort
  /// - Headline → ROND moyen (50–70) : assertif mais lisible
  /// - Title → ROND faible (20–30) : neutre avec caractère
  /// - Body/Label → ROND=0 : géométrique strict pour la lisibilité
  /// - GRAD varie selon le mode (dark = négatif)
  static TextTheme _buildTextTheme(double grad, ColorScheme scheme) {
    return TextTheme(
      // Display — titres très grands, très expressifs
      displayLarge:  _gsf(fontSize: 57, wght: 800, rond: 100, grad: grad),
      displayMedium: _gsf(fontSize: 45, wght: 800, rond: 90,  grad: grad),
      displaySmall:  _gsf(fontSize: 36, wght: 700, rond: 80,  grad: grad),

      // Headline — titres de page / section
      headlineLarge:  _gsf(fontSize: 32, wght: 700, rond: 70, grad: grad),
      headlineMedium: _gsf(fontSize: 28, wght: 700, rond: 60, grad: grad),
      headlineSmall:  _gsf(fontSize: 24, wght: 700, rond: 50, grad: grad),

      // Title — cartes, listes, labels importants
      titleLarge:  _gsf(fontSize: 22, wght: 600, rond: 30, grad: grad),
      titleMedium: _gsf(fontSize: 16, wght: 600, rond: 20, grad: grad),
      titleSmall:  _gsf(fontSize: 14, wght: 600, rond: 10, grad: grad),

      // Body — contenu principal, lisibilité maximale → ROND=0
      bodyLarge:  _gsf(fontSize: 16, wght: 400, rond: 0, grad: grad),
      bodyMedium: _gsf(fontSize: 14, wght: 400, rond: 0, grad: grad),
      bodySmall:  _gsf(fontSize: 12, wght: 400, rond: 0, grad: grad),

      // Label — boutons, chips, tags → ROND=0
      labelLarge:  _gsf(fontSize: 14, wght: 600, rond: 0, grad: grad),
      labelMedium: _gsf(fontSize: 12, wght: 500, rond: 0, grad: grad),
      labelSmall:  _gsf(fontSize: 11, wght: 500, rond: 0, grad: grad),
    );
  }

  /// Shorthand : Google Sans Flex avec les axes ROND, wght, GRAD configurés.
  /// Les fontVariations sont appliquées via copyWith car GoogleFonts ne les
  /// accepte pas directement en paramètre.
  static TextStyle _gsf({
    required double fontSize,
    required double wght,
    required double rond,
    required double grad,
    Color? color,
  }) {
    return GoogleFonts.googleSansFlex(
      fontSize: fontSize,
      color: color,
    ).copyWith(
      fontVariations: [
        FontVariation('wght', wght),
        FontVariation('ROND', rond),
        FontVariation('GRAD', grad),
        // opsz adaptatif : taille optique = taille de police
        FontVariation('opsz', fontSize.clamp(20, 48)),
      ],
    );
  }
}
