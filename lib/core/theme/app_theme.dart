import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Builds Cadence's three theme variants (light / dark / AMOLED) from a
/// single accent seed color, so switching accent in Settings re-derives a
/// full, consistent Material 3 ColorScheme rather than patching one color.
class AppTheme {
  AppTheme._();

  static ThemeData light(Color accent) => _build(
        accent: accent,
        brightness: Brightness.light,
        amoled: false,
      );

  static ThemeData dark(Color accent, {bool amoled = false}) => _build(
        accent: accent,
        brightness: Brightness.dark,
        amoled: amoled,
      );

  static ThemeData _build({
    required Color accent,
    required Brightness brightness,
    required bool amoled,
  }) {
    final scheme = _colorScheme(accent: accent, brightness: brightness, amoled: amoled);
    final textTheme = _textTheme(brightness);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: isDark ? scheme.surface : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? scheme.primary : scheme.onSurfaceVariant, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: textTheme.labelLarge!,
        secondaryLabelStyle: textTheme.labelLarge!.copyWith(color: scheme.primary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        extendedTextStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.onSurface.withValues(alpha: 0.1),
        circularTrackColor: scheme.onSurface.withValues(alpha: 0.1),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(8)),
        textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  static ColorScheme _colorScheme({
    required Color accent,
    required Brightness brightness,
    required bool amoled,
  }) {
    final base = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
    if (brightness == Brightness.light) return base;

    if (amoled) {
      return base.copyWith(
        surface: AppColors.amoledBackground,
        surfaceContainerLowest: AppColors.amoledBackground,
        surfaceContainerLow: AppColors.amoledSurface,
        surfaceContainer: AppColors.amoledSurfaceVariant,
        surfaceContainerHigh: AppColors.amoledSurfaceRaised,
        surfaceContainerHighest: AppColors.amoledSurfaceRaised,
      );
    }

    return base.copyWith(
      surface: AppColors.darkBackground,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceVariant,
      surfaceContainerHigh: AppColors.darkSurfaceRaised,
      surfaceContainerHighest: AppColors.darkSurfaceRaised,
    );
  }

  /// Sora carries headings/titles (the app's "voice"); Inter carries body and
  /// label text (built for small-size legibility on phone screens).
  static TextTheme _textTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
    return base.copyWith(
      displayLarge: GoogleFonts.sora(textStyle: base.displayLarge, fontWeight: FontWeight.w700, letterSpacing: -1.0),
      displayMedium: GoogleFonts.sora(textStyle: base.displayMedium, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: GoogleFonts.sora(textStyle: base.displaySmall, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.sora(textStyle: base.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.sora(textStyle: base.headlineMedium, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.sora(textStyle: base.headlineSmall, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.sora(textStyle: base.titleLarge, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.sora(textStyle: base.titleMedium, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(textStyle: base.titleSmall, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(textStyle: base.bodySmall, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(textStyle: base.labelLarge, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(textStyle: base.labelMedium, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(textStyle: base.labelSmall, fontWeight: FontWeight.w500),
    );
  }
}
