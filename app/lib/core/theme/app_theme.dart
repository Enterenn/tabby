import 'package:material_ui/material_ui.dart';
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

    // `vibrant` garde le cobalt en primary. Citron / vermillon sont
    // injectés ensuite — fromSeed les remplacerait par des cousins bleus.
    final scheme = _polaAccents(
      ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ),
    );
    final semantic = TabbySemanticColors.fromScheme(scheme);

    final typography = TabbyTypographyTokens.create(scheme: scheme, grad: grad);
    final textTheme =
        TabbyTypographyTokens.buildTextTheme(scheme: scheme, grad: grad);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'GoogleSansFlex',
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [shapes, typography, semantic, TabbySpaceTokens.standard],

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
        backgroundColor: scheme.surface,
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
        color: scheme.surfaceContainerLow,
        shape: shapes.cardShape,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
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
          minimumSize: const Size(64, 52),
          shape: shapes.buttonShape,
          side: BorderSide(color: scheme.outline, width: 1.5),
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

      hintColor: scheme.onSurfaceVariant.withValues(alpha: 0.42),
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
        hintStyle: TabbyTypographyTokens.flex(
          fontSize: 14,
          wght: 400,
          rond: 0,
          grad: grad,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.42),
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
          color: scheme.primary,
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
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: shapes.radiusLarge,
        ),
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
          final selected = states.contains(WidgetState.selected);
          return TabbyTypographyTokens.flex(
            fontSize: 11,
            wght: selected ? 700 : 500,
            rond: 0,
            grad: grad,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
        elevation: 0,
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

  /// Citron (tertiary + containers tonals) et vermillon (secondary plein).
  ///
  /// Les containers secondary suivent le citron pour que [FilledButton.tonal]
  /// et les surfaces « coral » M3 sortent en lime, pas en vermillon.
  static ColorScheme _polaAccents(ColorScheme base) {
    final dark = base.brightness == Brightness.dark;
    final lemonContainer =
        dark ? AppColors.lemonContainerDark : AppColors.lemon;
    final onLemonContainer =
        dark ? AppColors.onLemonContainerDark : AppColors.onLemon;
    return base.copyWith(
      secondary: AppColors.vermillion,
      onSecondary: AppColors.onVermillion,
      secondaryContainer: lemonContainer,
      onSecondaryContainer: onLemonContainer,
      tertiary: dark ? AppColors.lemon : AppColors.lemonInk,
      onTertiary: dark ? AppColors.onLemon : AppColors.lemon,
      tertiaryContainer: lemonContainer,
      onTertiaryContainer: onLemonContainer,
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
