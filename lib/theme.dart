import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModizkColors {
  // Primary background - Very Light Gray
  static const primaryBackground = Color(0xFFF8F8F8);
  // Secondary background - Light Gray  
  static const secondaryBackground = Color(0xFFEEEEEE);
  // Primary text & icons - Very Dark Gray
  static const primaryText = Color(0xFF212121);
  // Primary accent - Fiery Orange
  static const primaryAccent = Color(0xFFFF5722);
  // Secondary accent - Vivid Blue-Turquoise
  static const secondaryAccent = Color(0xFF00BCD4);
  // Secondary text - Medium Gray
  static const secondaryText = Color(0xFF707070);
  // Warning/Delete - Bright Red
  static const warning = Color(0xFFFF5722);
  // White for contrast
  static const white = Color(0xFFFFFFFF);
  // Dark mode surface
  static const darkSurface = Color(0xFF121212);
  // Dark mode on surface
  static const darkOnSurface = Color(0xFF212121);
}


class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: ModizkColors.primaryAccent,
    onPrimary: ModizkColors.white,
    primaryContainer: ModizkColors.secondaryBackground,
    onPrimaryContainer: ModizkColors.primaryText,
    secondary: ModizkColors.secondaryAccent,
    onSecondary: ModizkColors.white,
    tertiary: ModizkColors.secondaryAccent,
    onTertiary: ModizkColors.white,
    error: ModizkColors.warning,
    onError: ModizkColors.white,
    errorContainer: ModizkColors.secondaryBackground,
    onErrorContainer: ModizkColors.primaryText,
    surface: ModizkColors.primaryBackground,
    onSurface: ModizkColors.primaryText,
    onSurfaceVariant: ModizkColors.secondaryText,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: ModizkColors.primaryBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: ModizkColors.primaryBackground,
    foregroundColor: ModizkColors.primaryText,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: ModizkColors.secondaryBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ModizkColors.primaryAccent,
      foregroundColor: ModizkColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  iconTheme: IconThemeData(
    color: ModizkColors.primaryText,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: ModizkColors.primaryAccent,
    onPrimary: ModizkColors.white,
    primaryContainer: ModizkColors.secondaryText,
    onPrimaryContainer: ModizkColors.darkOnSurface,
    secondary: ModizkColors.secondaryAccent,
    onSecondary: ModizkColors.white,
    tertiary: ModizkColors.secondaryAccent,
    onTertiary: ModizkColors.white,
    error: ModizkColors.warning,
    onError: ModizkColors.white,
    errorContainer: ModizkColors.secondaryText,
    onErrorContainer: ModizkColors.darkOnSurface,
    surface: ModizkColors.darkSurface,
    onSurface: ModizkColors.darkOnSurface,
    onSurfaceVariant: ModizkColors.secondaryText,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ModizkColors.darkSurface,
  appBarTheme: AppBarTheme(
    backgroundColor: ModizkColors.darkSurface,
    foregroundColor: ModizkColors.darkOnSurface,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: ModizkColors.secondaryText,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ModizkColors.primaryAccent,
      foregroundColor: ModizkColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  iconTheme: IconThemeData(
    color: ModizkColors.darkOnSurface,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);
