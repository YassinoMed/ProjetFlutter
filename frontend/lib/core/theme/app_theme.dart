/// MediConnect Pro - Theme Configuration
/// Redesign aligned with official Figma exports
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════════════
  // ── Color Palette ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static const Color primaryColor = Color(0xFF004E99);
  static const Color primaryLight = Color(0xFF3B81F5);
  static const Color primaryDark = Color(0xFF003A73);
  static const Color primarySurface = Color(0xFFE8F0FF);

  static const Color secondaryColor = Color(0xFF8FB3F7);
  static const Color secondaryLight = Color(0xFFB8D0F8);
  static const Color secondaryDark = Color(0xFF5B7FC5);

  static const Color accentColor = Color(0xFFDCE8FB);
  static const Color accentLight = Color(0xFFF4F7FC);

  static const Color successColor = Color(0xFF00772E);
  static const Color warningColor = Color(0xFFF38C2B);
  static const Color errorColor = Color(0xFFD53E3E);
  static const Color infoColor = Color(0xFF2F6FE8);

  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray50 = Color(0xFFFBFCFF);
  static const Color neutralGray100 = Color(0xFFF4F7FC);
  static const Color neutralGray200 = Color(0xFFE6ECF4);
  static const Color neutralGray300 = Color(0xFFD5DDE8);
  static const Color neutralGray400 = Color(0xFFA4B0C2);
  static const Color neutralGray500 = Color(0xFF778398);
  static const Color neutralGray600 = Color(0xFF5C687B);
  static const Color neutralGray700 = Color(0xFF3C4758);
  static const Color neutralGray800 = Color(0xFF253041);
  static const Color neutralGray900 = Color(0xFF17212E);

  static const Color darkBackground = Color(0xFF080E20);
  static const Color darkSurface = Color(0xFF12224C);
  static const Color darkCard = Color(0xFF162B59);
  static const Color darkBorder = Color(0xFF233969);

  static const Color appointmentColor = primaryLight;
  static const Color chatColor = primaryColor;
  static const Color videoCallColor = Color(0xFF0B5AC3);
  static const Color recordsColor = successColor;

  // ══════════════════════════════════════════════════════════
  // ── Spacing & Radius ──────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacingMd,
  );

  // ══════════════════════════════════════════════════════════
  // ── Shadows ───────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: const Color(0xFF0A1630).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: const Color(0xFF0A1630).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: const Color(0xFF0A1630).withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get shadowPrimary => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  // ══════════════════════════════════════════════════════════
  // ── Gradients ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF0C67C8)],
  );

  static const LinearGradient medicalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningColor, Color(0xFFFFB25E)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF10224A), darkBackground],
  );

  // ══════════════════════════════════════════════════════════
  // ── Helpers ───────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static Color softColor(Color color, [double alpha = 0.12]) {
    return color.withValues(alpha: alpha);
  }

  static BoxDecoration surfaceDecoration({
    Color? color,
    Color? borderColor,
    BorderRadius? borderRadius,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color ?? neutralWhite,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLg),
      border: Border.all(color: borderColor ?? neutralGray200),
      boxShadow: elevated ? shadowSm : const [],
    );
  }

  static BoxDecoration darkSurfaceDecoration({
    Color? color,
    Color? borderColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? darkSurface,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLg),
      border: Border.all(color: borderColor ?? darkBorder),
      boxShadow: shadowMd,
    );
  }

  // ══════════════════════════════════════════════════════════
  // ── Text Styles ───────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _roboto({
    required double size,
    required FontWeight weight,
    double height = 1.45,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.roboto(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get headlineLarge => _inter(
        size: 32,
        weight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.8,
      );

  static TextStyle get headlineMedium => _inter(
        size: 26,
        weight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.6,
      );

  static TextStyle get headlineSmall => _inter(
        size: 22,
        weight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.4,
      );

  static TextStyle get titleLarge => _inter(
        size: 20,
        weight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get titleMedium => _inter(
        size: 17,
        weight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get titleSmall => _inter(
        size: 14,
        weight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get bodyLarge => _roboto(
        size: 16,
        weight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => _roboto(
        size: 14,
        weight: FontWeight.w400,
      );

  static TextStyle get bodySmall => _roboto(
        size: 12,
        weight: FontWeight.w400,
      );

  static TextStyle get labelLarge => _inter(
        size: 14,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => _inter(
        size: 11,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0.4,
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
          onPrimaryContainer: primaryDark,
          secondary: secondaryColor,
          onSecondary: neutralGray900,
          secondaryContainer: accentColor,
          tertiary: successColor,
          onTertiary: neutralWhite,
          surface: neutralWhite,
          onSurface: neutralGray900,
          error: errorColor,
          onError: neutralWhite,
          outline: neutralGray300,
        ),
        scaffoldBackgroundColor: neutralGray50,
        cardColor: neutralWhite,
        splashFactory: InkRipple.splashFactory,
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
          scrolledUnderElevation: 0,
          backgroundColor: neutralGray50,
          foregroundColor: neutralGray900,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: titleLarge.copyWith(color: neutralGray900),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: neutralWhite,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: const BorderSide(color: neutralGray200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: neutralWhite,
            elevation: 0,
            disabledBackgroundColor: neutralGray300,
            disabledForegroundColor: neutralGray500,
            padding: const EdgeInsets.symmetric(
              horizontal: spacingLg,
              vertical: spacingMd,
            ),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: labelLarge.copyWith(color: neutralWhite),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            backgroundColor: neutralWhite,
            padding: const EdgeInsets.symmetric(
              horizontal: spacingLg,
              vertical: spacingMd,
            ),
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: neutralGray300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: labelLarge.copyWith(color: primaryColor),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: labelLarge.copyWith(color: primaryColor),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: neutralWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingMd,
          ),
          hintStyle: bodyMedium.copyWith(color: neutralGray400),
          errorStyle: bodySmall.copyWith(color: errorColor),
          prefixIconColor: neutralGray500,
          suffixIconColor: neutralGray500,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: neutralGray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: neutralGray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: primaryColor, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: errorColor, width: 1.4),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: neutralGray100,
          selectedColor: primarySurface,
          secondarySelectedColor: primarySurface,
          disabledColor: neutralGray100,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingXs,
          ),
          labelStyle: bodySmall.copyWith(color: neutralGray700),
          secondaryLabelStyle: bodySmall.copyWith(color: primaryColor),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: neutralGray200),
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: primaryColor,
          unselectedLabelColor: neutralGray500,
          labelStyle: labelSmall,
          unselectedLabelStyle: labelSmall.copyWith(color: neutralGray500),
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: primarySurface,
            borderRadius: BorderRadius.circular(radiusFull),
            border: Border.all(color: secondaryLight),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          splashFactory: NoSplash.splashFactory,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: neutralWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: neutralGray200,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: neutralGray900,
          contentTextStyle: bodyMedium.copyWith(color: neutralWhite),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          backgroundColor: neutralWhite,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radiusXl),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return neutralWhite;
            }
            return neutralWhite;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryLight;
            }
            return neutralGray300;
          }),
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
          onPrimary: neutralWhite,
          primaryContainer: darkSurface,
          onPrimaryContainer: neutralWhite,
          secondary: secondaryLight,
          onSecondary: darkBackground,
          secondaryContainer: darkCard,
          tertiary: successColor,
          onTertiary: neutralWhite,
          surface: darkSurface,
          onSurface: neutralWhite,
          error: Color(0xFFF87171),
          onError: darkBackground,
          outline: darkBorder,
        ),
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkSurface,
        splashFactory: InkRipple.splashFactory,
        textTheme: TextTheme(
          headlineLarge: headlineLarge.copyWith(color: neutralWhite),
          headlineMedium: headlineMedium.copyWith(color: neutralWhite),
          headlineSmall: headlineSmall.copyWith(color: neutralWhite),
          titleLarge: titleLarge.copyWith(color: neutralWhite),
          titleMedium: titleMedium.copyWith(color: neutralGray100),
          titleSmall: titleSmall.copyWith(color: neutralGray300),
          bodyLarge: bodyLarge.copyWith(color: neutralGray300),
          bodyMedium: bodyMedium.copyWith(color: neutralGray400),
          bodySmall: bodySmall.copyWith(color: neutralGray500),
          labelLarge: labelLarge.copyWith(color: neutralGray100),
          labelSmall: labelSmall.copyWith(color: neutralGray400),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: darkBackground,
          foregroundColor: neutralWhite,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: titleLarge.copyWith(color: neutralWhite),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkSurface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: const BorderSide(color: darkBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryLight,
            foregroundColor: neutralWhite,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(
              horizontal: spacingLg,
              vertical: spacingMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: labelLarge.copyWith(color: neutralWhite),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: neutralWhite,
            backgroundColor: darkSurface,
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: darkBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: labelLarge.copyWith(color: neutralWhite),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: secondaryLight,
            textStyle: labelLarge.copyWith(color: secondaryLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingMd,
          ),
          hintStyle: bodyMedium.copyWith(color: neutralGray500),
          prefixIconColor: neutralGray400,
          suffixIconColor: neutralGray400,
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
            borderSide: const BorderSide(color: primaryLight, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: errorColor, width: 1.4),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkCard,
          selectedColor: darkSurface,
          secondarySelectedColor: darkSurface,
          disabledColor: darkCard,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingXs,
          ),
          labelStyle: bodySmall.copyWith(color: neutralGray300),
          secondaryLabelStyle: bodySmall.copyWith(color: neutralWhite),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: darkBorder),
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: neutralWhite,
          unselectedLabelColor: neutralGray500,
          labelStyle: labelSmall,
          unselectedLabelStyle: labelSmall.copyWith(color: neutralGray500),
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(radiusFull),
            border: Border.all(color: darkBorder),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          splashFactory: NoSplash.splashFactory,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryLight,
          foregroundColor: neutralWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: darkBorder,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: darkCard,
          contentTextStyle: bodyMedium.copyWith(color: neutralWhite),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          backgroundColor: darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radiusXl),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return neutralWhite;
            }
            return neutralWhite;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryLight;
            }
            return darkBorder;
          }),
        ),
      );
}
