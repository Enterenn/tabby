import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// À appeler une seule fois dans main() avant runApp().
  static void configureSymbols() {
    // Rounded — fill=0 par défaut, weight=400, opsz=24
    MaterialSymbolsBase.setRoundedVariationDefaults(
      fill: 0,
      weight: 400,
      grade: 0,
      opticalSize: 24,
    );
  }

  static ThemeData _build(Brightness brightness) {
    // M3 génère toute la palette tonale depuis la couleur de marque.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      // On garde la teinte exacte de la marque pour primary.
      primary: AppColors.primary,
      onPrimary: const Color(0xFF2E2A22),
      // error mappe sur notre couleur danger
      error: AppColors.danger,
      onError: Colors.white,
    );

    // Figtree appliqué à tout le type scale M3 en une ligne.
    final textTheme = GoogleFonts.figtreeTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,

      // Fond légèrement teinté (surfaceContainerLow = teinte chaude générée par M3)
      scaffoldBackgroundColor: scheme.surfaceContainerLow,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: scheme.primary,
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),

      // M3 Card : elevation 1 avec teinture primaire
      cardTheme: CardThemeData(
        elevation: 1,
        surfaceTintColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      // FilledButton M3 : utilise primary/onPrimary du scheme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      // OutlinedButton M3
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input M3 : fond surfaceContainerHighest, bords arrondis
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        labelStyle: GoogleFonts.figtree(color: scheme.onSurfaceVariant),
        floatingLabelStyle: GoogleFonts.figtree(color: scheme.primary),
      ),

      // NavigationBar M3 — Symbols filled quand sélectionné, outlined sinon
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onPrimaryContainer,
              fill: 1,  // icône remplie = état actif (M3 Symbols)
              weight: 600,
            );
          }
          return IconThemeData(
            color: scheme.onSurfaceVariant,
            fill: 0,  // icône outline = état inactif
            weight: 400,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.figtree(fontSize: 11);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface);
          }
          return base.copyWith(color: scheme.onSurfaceVariant);
        }),
        elevation: 3,
        surfaceTintColor: scheme.primary,
      ),

      // SnackBar M3
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.figtree(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialog M3
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    );
  }
}
