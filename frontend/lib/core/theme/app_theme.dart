/// MediConnect Pro - Theme Configuration
/// Premium medical theme with dark mode support
/// CDC: UI/UX premium, mode sombre, accessibilité WCAG AA
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════════════
  // ── Color Palette ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  // Primary - Medical Blue
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySurface = Color(0xFFEFF6FF);

  // Secondary - Teal/Medical Green
  static const Color secondaryColor = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color secondaryDark = Color(0xFF0F766E);

  // Accent - Warm Amber
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);

  // Semantic Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray50 = Color(0xFFF9FAFB);
  static const Color neutralGray100 = Color(0xFFF3F4F6);
  static const Color neutralGray200 = Color(0xFFE5E7EB);
  static const Color neutralGray300 = Color(0xFFD1D5DB);
  static const Color neutralGray400 = Color(0xFF9CA3AF);
  static const Color neutralGray500 = Color(0xFF6B7280);
  static const Color neutralGray600 = Color(0xFF4B5563);
  static const Color neutralGray700 = Color(0xFF374151);
  static const Color neutralGray800 = Color(0xFF1F2937);
  static const Color neutralGray900 = Color(0xFF111827);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);

  // Medical specific
  static const Color appointmentColor = Color(0xFF8B5CF6);
  static const Color chatColor = Color(0xFF06B6D4);
  static const Color videoCallColor = Color(0xFFEC4899);
  static const Color recordsColor = Color(0xFF14B8A6);

  // ══════════════════════════════════════════════════════════
  // ── Spacing & Radius ──────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ══════════════════════════════════════════════════════════
  // ── Shadows ───────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 25,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowPrimary => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // ══════════════════════════════════════════════════════════
  // ── Gradients ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF7C3AED)],
  );

  static const LinearGradient medicalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // ══════════════════════════════════════════════════════════
  // ── Text Styles ───────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ══════════════════════════════════════════════════════════
  // ── Light Theme ───────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: neutralWhite,
      primaryContainer: primarySurface,
      secondary: secondaryColor,
      onSecondary: neutralWhite,
      tertiary: accentColor,
      surface: neutralWhite,
      onSurface: neutralGray900,
      error: errorColor,
      onError: neutralWhite,
      outline: neutralGray300,
    ),
    scaffoldBackgroundColor: neutralGray50,
    textTheme: TextTheme(
      headlineLarge: headlineLarge.copyWith(color: neutralGray900),
      headlineMedium: headlineMedium.copyWith(color: neutralGray900),
      headlineSmall: headlineSmall.copyWith(color: neutralGray900),
      titleLarge: titleLarge.copyWith(color: neutralGray900),
      titleMedium: titleMedium.copyWith(color: neutralGray800),
      titleSmall: titleSmall.copyWith(color: neutralGray700),
      bodyLarge: bodyLarge.copyWith(color: neutralGray700),
      bodyMedium: bodyMedium.copyWith(color: neutralGray600),
      bodySmall: bodySmall.copyWith(color: neutralGray500),
      labelLarge: labelLarge.copyWith(color: neutralGray700),
      labelSmall: labelSmall.copyWith(color: neutralGray500),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: neutralWhite,
      foregroundColor: neutralGray900,
      titleTextStyle: titleLarge.copyWith(color: neutralGray900),
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: neutralGray200),
      ),
      color: neutralWhite,
      margin: const EdgeInsets.symmetric(vertical: spacingSm),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: neutralWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: labelLarge.copyWith(color: neutralWhite),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        side: const BorderSide(color: primaryColor),
        textStyle: labelLarge,
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutralGray50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: neutralGray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: neutralGray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor),
      ),
      hintStyle: bodyMedium.copyWith(color: neutralGray400),
      errorStyle: bodySmall.copyWith(color: errorColor),
      prefixIconColor: neutralGray500,
      suffixIconColor: neutralGray500,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primarySurface,
      labelStyle: bodySmall.copyWith(color: primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingSm,
        vertical: spacingXs,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: neutralWhite,
      selectedItemColor: primaryColor,
      unselectedItemColor: neutralGray400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: neutralWhite,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: neutralGray200,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXl),
        ),
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════
  // ── Dark Theme ────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      onPrimary: darkBackground,
      primaryContainer: Color(0xFF1E3A5F),
      secondary: secondaryLight,
      onSecondary: darkBackground,
      tertiary: accentLight,
      surface: darkSurface,
      onSurface: neutralGray100,
      error: Color(0xFFF87171),
      onError: darkBackground,
      outline: darkBorder,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: TextTheme(
      headlineLarge: headlineLarge.copyWith(color: neutralWhite),
      headlineMedium: headlineMedium.copyWith(color: neutralWhite),
      headlineSmall: headlineSmall.copyWith(color: neutralWhite),
      titleLarge: titleLarge.copyWith(color: neutralGray100),
      titleMedium: titleMedium.copyWith(color: neutralGray200),
      titleSmall: titleSmall.copyWith(color: neutralGray300),
      bodyLarge: bodyLarge.copyWith(color: neutralGray300),
      bodyMedium: bodyMedium.copyWith(color: neutralGray400),
      bodySmall: bodySmall.copyWith(color: neutralGray500),
      labelLarge: labelLarge.copyWith(color: neutralGray200),
      labelSmall: labelSmall.copyWith(color: neutralGray400),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: darkSurface,
      foregroundColor: neutralWhite,
      titleTextStyle: titleLarge.copyWith(color: neutralWhite),
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: darkBorder),
      ),
      color: darkSurface,
      margin: const EdgeInsets.symmetric(vertical: spacingSm),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: neutralWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: labelLarge.copyWith(color: neutralWhite),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        side: const BorderSide(color: primaryLight),
        textStyle: labelLarge,
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor),
      ),
      hintStyle: bodyMedium.copyWith(color: neutralGray500),
      prefixIconColor: neutralGray400,
      suffixIconColor: neutralGray400,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryLight,
      unselectedItemColor: neutralGray500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXl),
        ),
      ),
    ),
  );
}
