import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

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
    final grad = isDark ? -25.0 : 0.0;
    final shapes = TabbyShapeTokens.standard;
    final semantic =
        isDark ? TabbySemanticColors.dark : TabbySemanticColors.light;

    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    final scheme = base.copyWith(
      primary: isDark ? AppColors.primaryDark : AppColors.primary,
      onPrimary: isDark ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
      primaryContainer: isDark
          ? AppColors.primaryContainerDark
          : AppColors.primaryContainerLight,
      onPrimaryContainer: isDark
          ? AppColors.onPrimaryContainerDark
          : AppColors.onPrimaryContainerLight,
      secondary: isDark ? AppColors.secondaryDark : AppColors.secondary,
      onSecondary: isDark ? AppColors.onSecondaryDark : Colors.white,
      secondaryContainer: isDark
          ? AppColors.secondaryContainerDark
          : AppColors.secondaryContainerLight,
      onSecondaryContainer: isDark
          ? AppColors.onSecondaryContainerDark
          : AppColors.onSecondaryContainerLight,
      tertiary: isDark ? AppColors.tertiaryDark : AppColors.tertiary,
      onTertiary: isDark ? AppColors.onTertiaryDark : Colors.white,
      tertiaryContainer: isDark
          ? AppColors.tertiaryContainerDark
          : AppColors.tertiaryContainerLight,
      onTertiaryContainer: isDark
          ? AppColors.onTertiaryContainerDark
          : AppColors.onTertiaryContainerLight,
      error: semantic.danger,
      onError: semantic.onDanger,
      errorContainer: semantic.dangerContainer,
      onErrorContainer: semantic.onDangerContainer,
      surface: isDark ? AppColors.surfaceDark : const Color(0xFFFFFBFE),
      onSurface: isDark ? AppColors.onSurfaceDark : const Color(0xFF1C1B1F),
      surfaceContainerLowest: isDark
          ? AppColors.surfaceContainerLowestDark
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark
          ? AppColors.surfaceContainerLowDark
          : const Color(0xFFF7F2FA),
      surfaceContainer: isDark
          ? AppColors.surfaceContainerDark
          : const Color(0xFFF3EDF7),
      surfaceContainerHigh: isDark
          ? AppColors.surfaceContainerHighDark
          : const Color(0xFFECE6F0),
      surfaceContainerHighest: isDark
          ? AppColors.surfaceContainerHighestDark
          : const Color(0xFFE6E0E9),
      onSurfaceVariant:
          isDark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F),
      outline: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E),
      outlineVariant:
          isDark ? const Color(0xFF49454F) : const Color(0xFFCAC4D0),
    );

    final typography = TabbyTypographyTokens.create(scheme: scheme, grad: grad);
    final textTheme =
        TabbyTypographyTokens.buildTextTheme(scheme: scheme, grad: grad);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'GoogleSansFlex',
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      extensions: [shapes, typography, semantic],

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
        scrolledUnderElevation: 0,
        surfaceTintColor: scheme.primary,
        titleTextStyle: TabbyTypographyTokens.flex(
          fontSize: 24,
          wght: 600,
          rond: 10,
          grad: grad,
          color: scheme.onSurface,
          height: 32 / 24,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: shapes.cardShape,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: shapes.buttonShape,
          textStyle: TabbyTypographyTokens.flex(
            fontSize: 16,
            wght: 700,
            rond: 0,
            grad: grad,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: shapes.buttonShape,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: TabbyTypographyTokens.flex(
            fontSize: 15,
            wght: 600,
            rond: 0,
            grad: grad,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TabbyTypographyTokens.flex(
            fontSize: 14,
            wght: 600,
            rond: 0,
            grad: grad,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: shapes.radiusLarge,
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: TabbyTypographyTokens.flex(
          fontSize: 14,
          wght: 400,
          rond: 0,
          grad: grad,
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: TabbyTypographyTokens.flex(
          fontSize: 12,
          wght: 600,
          rond: 0,
          grad: grad,
          color: scheme.secondary,
        ),
      ),

      chipTheme: ChipThemeData(
        shape: shapes.buttonShape,
        side: BorderSide.none,
        labelStyle: TabbyTypographyTokens.flex(
          fontSize: 13,
          wght: 600,
          rond: 0,
          grad: grad,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: shapes.circle(),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: shapes.modalTopShape,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        dragHandleSize: const Size(40, 4),
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: shapes.radiusLarge,
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onSecondaryContainer,
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
          final selected = states.contains(WidgetState.selected);
          return TabbyTypographyTokens.flex(
            fontSize: 11,
            wght: selected ? 700 : 500,
            rond: 0,
            grad: grad,
            color: selected ? scheme.secondary : scheme.onSurfaceVariant,
          );
        }),
        elevation: 0,
        surfaceTintColor: scheme.primary,
        height: 72,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        elevation: 0,
        contentTextStyle: TabbyTypographyTokens.flex(
          fontSize: 14,
          wght: 400,
          rond: 0,
          grad: grad,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: shapes.radiusLarge),
      ),

      dialogTheme: DialogThemeData(
        shape: shapes.cardShape,
        elevation: 0,
        titleTextStyle: TabbyTypographyTokens.flex(
          fontSize: 22,
          wght: 800,
          rond: 0,
          grad: grad,
          color: scheme.onSurface,
        ),
        backgroundColor: scheme.surfaceContainerHigh,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: shapes.radiusLarge),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  /// Rétrocompatibilité — délégué vers [TabbyTypographyTokens.flex].
  static TextStyle flex({
    required double fontSize,
    required double wght,
    required double rond,
    double grad = 0,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TabbyTypographyTokens.flex(
      fontSize: fontSize,
      wght: wght,
      rond: rond,
      grad: grad,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
