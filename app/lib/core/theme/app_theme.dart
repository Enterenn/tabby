import 'package:flutter/material.dart';
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
      // Secondary — indigo-violet (froid)
      secondary: isDark ? AppColors.secondaryDark : AppColors.secondary,
      onSecondary: isDark ? AppColors.onSecondaryDark : Colors.white,
      secondaryContainer: isDark
          ? AppColors.secondaryContainerDark
          : AppColors.secondaryContainerLight,
      onSecondaryContainer: isDark
          ? AppColors.onSecondaryContainerDark
          : AppColors.onSecondaryContainerLight,
      // Tertiary — teal-menthe (froid)
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
      fontFamily: 'GoogleSansFlex',
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
        titleTextStyle: flex(
          fontSize: 24, wght: 500, rond: 70, grad: grad,
          color: scheme.onSurface, height: 32 / 24,
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
          textStyle: flex(fontSize: 16, wght: 600, rond: 0, grad: grad, letterSpacing: 0.1),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: flex(fontSize: 15, wght: 600, rond: 0, grad: grad),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: flex(fontSize: 14, wght: 600, rond: 0, grad: grad),
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
        labelStyle: flex(
          fontSize: 14, wght: 400, rond: 0, grad: grad,
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: flex(
          fontSize: 12, wght: 600, rond: 20, grad: grad,
          color: scheme.secondary,
        ),
      ),

      // ── Chips — pill ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50)),
        side: BorderSide.none,
        labelStyle: flex(fontSize: 13, wght: 600, rond: 30, grad: grad),
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
        indicatorColor: scheme.secondaryContainer,
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
          return flex(
            fontSize: 11,
            wght: selected ? 700 : 400,
            rond: selected ? 40 : 0,
            grad: grad,
            color: selected ? scheme.secondary : scheme.onSurfaceVariant,
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
        contentTextStyle: flex(
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
        titleTextStyle: flex(
          fontSize: 22, wght: 800, rond: 80, grad: grad,
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

  // Type scale M3 Expressive (emphasized) :
  // https://m3.material.io/styles/typography/type-scale-tokens
  // https://m3.material.io/blog/building-with-m3-expressive
  // Display / Headline → ROND max (voix expressive)
  // Body / Label → ROND 0 (lisibilité)
  static TextTheme _buildTextTheme(double grad, ColorScheme scheme) {
    TextStyle role({
      required double size,
      required double line,
      required double wght,
      required double rond,
      double tracking = 0,
    }) {
      return flex(
        fontSize: size,
        wght: wght,
        rond: rond,
        grad: grad,
        height: line / size,
        letterSpacing: tracking,
        color: scheme.onSurface,
      );
    }

    return TextTheme(
      // Display — 57 / 45 / 36 — emphasized medium + round terminals
      displayLarge:  role(size: 57, line: 64, wght: 500, rond: 100, tracking: -0.25),
      displayMedium: role(size: 45, line: 52, wght: 500, rond: 100),
      displaySmall:  role(size: 36, line: 44, wght: 500, rond: 100),

      // Headline — 32 / 28 / 24
      headlineLarge:  role(size: 32, line: 40, wght: 500, rond: 80),
      headlineMedium: role(size: 28, line: 36, wght: 500, rond: 80),
      headlineSmall:  role(size: 24, line: 32, wght: 500, rond: 70),

      // Title — 22 / 16 / 14 — plus dense
      titleLarge:  role(size: 22, line: 28, wght: 500, rond: 40),
      titleMedium: role(size: 16, line: 24, wght: 600, rond: 20, tracking: 0.15),
      titleSmall:  role(size: 14, line: 20, wght: 600, rond: 15, tracking: 0.1),

      // Body — géométrique, ROND 0
      bodyLarge:  role(size: 16, line: 24, wght: 400, rond: 0, tracking: 0.5),
      bodyMedium: role(size: 14, line: 20, wght: 400, rond: 0, tracking: 0.25),
      bodySmall:  role(size: 12, line: 16, wght: 400, rond: 0, tracking: 0.4),

      // Label
      labelLarge:  role(size: 14, line: 20, wght: 600, rond: 0, tracking: 0.1),
      labelMedium: role(size: 12, line: 16, wght: 600, rond: 0, tracking: 0.5),
      labelSmall:  role(size: 11, line: 16, wght: 600, rond: 0, tracking: 0.5),
    );
  }

  /// Google Sans Flex (fichier variable bundlé).
  /// Axes : wght 1–1000, ROND 0–100, GRAD -200–150, opsz 8–144.
  static TextStyle flex({
    required double fontSize,
    required double wght,
    required double rond,
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
}
