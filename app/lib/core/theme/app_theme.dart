import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static void configureSymbols() {
    MaterialSymbolsBase.setRoundedVariationDefaults(
      fill: 0, weight: 400, grade: 0, opticalSize: 24,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final grad   = isDark ? -25.0 : 0.0;

    // ── ColorScheme ──────────────────────────────────────────────────────────
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: const Color(0xFF2E2A22),
    );

    final scheme = base.copyWith(
      // Secondary — corail-orange
      secondary: isDark ? AppColors.secondaryDark : AppColors.secondary,
      onSecondary: isDark ? AppColors.onSecondaryDark : Colors.white,
      secondaryContainer: isDark
          ? AppColors.secondaryContainerDark
          : AppColors.secondaryContainerLight,
      onSecondaryContainer: isDark
          ? AppColors.onSecondaryContainerDark
          : AppColors.onSecondaryContainerLight,
      // Tertiary — rose-magenta
      tertiary: isDark ? AppColors.tertiaryDark : AppColors.tertiary,
      onTertiary: isDark ? AppColors.onTertiaryDark : Colors.white,
      tertiaryContainer: isDark
          ? AppColors.tertiaryContainerDark
          : AppColors.tertiaryContainerLight,
      onTertiaryContainer: isDark
          ? AppColors.onTertiaryContainerDark
          : AppColors.onTertiaryContainerLight,
      // Error
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _buildTextTheme(grad, scheme),
      scaffoldBackgroundColor: scheme.surfaceContainerLow,

      // ── Transitions M3 Emphasized ──────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS:     ZoomPageTransitionsBuilder(),
          TargetPlatform.linux:   ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS:   ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: scheme.primary,
        titleTextStyle: _gsf(
          fontSize: 24, wght: 800, rond: 80, grad: grad,
          color: scheme.onSurface,
        ),
      ),

      // ── Cards M3 Expressive — 28dp ────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Buttons — pill shape (28dp) ───────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          textStyle: _gsf(fontSize: 16, wght: 700, rond: 40, grad: grad),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: _gsf(fontSize: 15, wght: 600, rond: 20, grad: grad),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: _gsf(fontSize: 14, wght: 600, rond: 0, grad: grad),
        ),
      ),

      // ── Inputs — 16dp ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: _gsf(
          fontSize: 14, wght: 400, rond: 0, grad: grad,
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: _gsf(
          fontSize: 12, wght: 600, rond: 0, grad: grad,
          color: scheme.primary,
        ),
      ),

      // ── Chips — pill ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50)),
        side: BorderSide.none,
        labelStyle: _gsf(fontSize: 13, wght: 600, rond: 0, grad: grad),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),

      // ── Bottom sheets — 28dp top ──────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        dragHandleSize: const Size(40, 4),
      ),

      // ── NavigationBar ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onPrimaryContainer, fill: 1, weight: 600);
          }
          return IconThemeData(
            color: scheme.onSurfaceVariant, fill: 0, weight: 400);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _gsf(
            fontSize: 11,
            wght: selected ? 700 : 400,
            rond: 0,
            grad: grad,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        elevation: 4,
        surfaceTintColor: scheme.primary,
        height: 72,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: _gsf(
          fontSize: 14, wght: 400, rond: 0, grad: grad,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),

      // ── Dialogs — 28dp ────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        titleTextStyle: _gsf(
          fontSize: 20, wght: 700, rond: 60, grad: grad,
          color: scheme.onSurface,
        ),
        backgroundColor: scheme.surfaceContainerHigh,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),

      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant, thickness: 1),
    );
  }

  // ── Type scale M3 Expressive ────────────────────────────────────────────────
  // Display → ROND élevé (80-100) : impact maximal
  // Headline → ROND moyen (50-70) : assertif
  // Title → ROND faible (10-30)
  // Body/Label → ROND=0 : lisibilité pure
  static TextTheme _buildTextTheme(double grad, ColorScheme scheme) {
    return TextTheme(
      displayLarge:  _gsf(fontSize: 57, wght: 900, rond: 100, grad: grad),
      displayMedium: _gsf(fontSize: 45, wght: 900, rond: 100, grad: grad),
      displaySmall:  _gsf(fontSize: 36, wght: 800, rond: 90,  grad: grad),

      headlineLarge:  _gsf(fontSize: 32, wght: 800, rond: 70, grad: grad),
      headlineMedium: _gsf(fontSize: 28, wght: 800, rond: 60, grad: grad),
      headlineSmall:  _gsf(fontSize: 24, wght: 800, rond: 50, grad: grad),

      titleLarge:  _gsf(fontSize: 22, wght: 700, rond: 30, grad: grad),
      titleMedium: _gsf(fontSize: 16, wght: 600, rond: 20, grad: grad),
      titleSmall:  _gsf(fontSize: 14, wght: 600, rond: 10, grad: grad),

      bodyLarge:  _gsf(fontSize: 16, wght: 400, rond: 0, grad: grad),
      bodyMedium: _gsf(fontSize: 14, wght: 400, rond: 0, grad: grad),
      bodySmall:  _gsf(fontSize: 12, wght: 400, rond: 0, grad: grad),

      labelLarge:  _gsf(fontSize: 14, wght: 700, rond: 0, grad: grad),
      labelMedium: _gsf(fontSize: 12, wght: 600, rond: 0, grad: grad),
      labelSmall:  _gsf(fontSize: 11, wght: 500, rond: 0, grad: grad),
    );
  }

  static TextStyle _gsf({
    required double fontSize,
    required double wght,
    required double rond,
    required double grad,
    Color? color,
  }) {
    return GoogleFonts.googleSansFlex(fontSize: fontSize, color: color)
        .copyWith(fontVariations: [
      FontVariation('wght', wght),
      FontVariation('ROND', rond),
      FontVariation('GRAD', grad),
      FontVariation('opsz', fontSize.clamp(20, 48)),
    ]);
  }
}
