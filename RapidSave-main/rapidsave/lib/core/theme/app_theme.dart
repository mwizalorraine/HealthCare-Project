import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.teal,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.teal,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.grey100,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: _appBarTheme(AppColors.white, AppColors.textPrimary, Brightness.dark),
      cardTheme: _cardTheme(AppColors.card, AppColors.border),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(AppColors.white),
      bottomNavigationBarTheme: _bottomNavTheme(AppColors.white),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      chipTheme: _chipTheme(),
      dialogTheme: _dialogTheme(AppColors.white),
      switchTheme: _switchTheme(),
    );
  }

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.teal,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurface,
        outline: AppColors.darkBorder,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      appBarTheme: _appBarTheme(AppColors.darkCard, AppColors.darkTextPrimary, Brightness.light),
      cardTheme: _cardTheme(AppColors.darkCard, AppColors.darkBorder),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(AppColors.darkInputFill),
      bottomNavigationBarTheme: _bottomNavTheme(AppColors.darkCard),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 1),
      chipTheme: _chipTheme(),
      dialogTheme: _dialogTheme(AppColors.darkCard),
      switchTheme: _switchTheme(),
    );
  }

  // ── Shared builders ────────────────────────────────────────────────────────
  static TextTheme _textTheme(TextTheme base, Color primary, Color secondary) {
    return GoogleFonts.workSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.workSans(fontSize: 32, fontWeight: FontWeight.w800, color: primary),
      displayMedium: GoogleFonts.workSans(fontSize: 28, fontWeight: FontWeight.w800, color: primary),
      displaySmall: GoogleFonts.workSans(fontSize: 24, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w600, color: primary),
      titleMedium: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
      titleSmall: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  static AppBarTheme _appBarTheme(Color bg, Color fg, Brightness statusBarBrightness) {
    return AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: statusBarBrightness,
      ),
      iconTheme: IconThemeData(color: fg, size: 24),
    );
  }

  static CardThemeData _cardTheme(Color color, Color borderColor) {
    return CardThemeData(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        side: BorderSide(color: borderColor, width: 0.5),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
        elevation: 0,
        textStyle: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
        side: const BorderSide(color: AppColors.teal, width: 1.5),
        textStyle: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Color fill) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      hintStyle: GoogleFonts.workSans(color: AppColors.textHint, fontSize: 14),
      labelStyle: GoogleFonts.workSans(color: AppColors.textSecondary, fontSize: 14),
      errorStyle: GoogleFonts.workSans(color: AppColors.danger, fontSize: 12),
      prefixIconColor: AppColors.grey400,
      suffixIconColor: AppColors.grey400,
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme(Color bg) {
    return BottomNavigationBarThemeData(
      backgroundColor: bg,
      selectedItemColor: AppColors.teal,
      unselectedItemColor: AppColors.grey400,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.workSans(fontSize: 11),
    );
  }

  static ChipThemeData _chipTheme() {
    return ChipThemeData(
      backgroundColor: AppColors.tealLight,
      selectedColor: AppColors.teal,
      labelStyle: GoogleFonts.workSans(fontSize: 13, color: AppColors.tealDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  static DialogThemeData _dialogTheme(Color bg) {
    return DialogThemeData(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
    );
  }

  static SwitchThemeData _switchTheme() {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return AppColors.grey400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.tealLight;
        return AppColors.grey200;
      }),
    );
  }
}
