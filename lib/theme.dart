import 'package:flutter/material.dart';

class LightModeColors {
  // Light theme with better contrast
  static const lightPrimary = Color(0xFF1A1A1A); // Very dark gray for better contrast
  static const lightOnPrimary = Color(0xFFFFFFFF); // Pure white
  static const lightPrimaryContainer = Color(0xFFF0F0F0); // Light gray
  static const lightOnPrimaryContainer = Color(0xFF1A1A1A); // Very dark gray text
  static const lightSecondary = Color(0xFF4A90E2); // Blue for secondary elements
  static const lightOnSecondary = Color(0xFFFFFFFF); // White text
  static const lightTertiary = Color(0xFF50C878); // Green for tertiary elements
  static const lightOnTertiary = Color(0xFFFFFFFF); // White text
  static const lightError = Color(0xFFE53E3E); // Red for errors
  static const lightOnError = Color(0xFFFFFFFF); // White text
  static const lightErrorContainer = Color(0xFFFFEBEE); // Light red background
  static const lightOnErrorContainer = Color(0xFFE53E3E); // Red text
  static const lightInversePrimary = Color(0xFFCCCCCC); // Light gray
  static const lightShadow = Color(0xFF000000); // Black shadow
  static const lightSurface = Color(0xFFFFFFFF); // Pure white background
  static const lightOnSurface = Color(0xFF1A1A1A); // Very dark gray text for better contrast
  static const lightAppBarBackground = Color(0xFFFFFFFF); // White app bar
  static const lightAccent = Color(0xFF4A90E2); // Blue accent
  static const lightCardBackground = Color(0xFFFFFFFF); // White cards
  static const lightBorderColor = Color(0xFFE0E0E0); // Light gray borders
  static const lightTextPrimary = Color(0xFF1A1A1A); // Very dark gray for primary text
  static const lightTextSecondary = Color(0xFF666666); // Medium gray for secondary text
  static const lightTextHint = Color(0xFF999999); // Light gray for hint text
}

class DarkModeColors {
  // Dark theme with better contrast
  static const darkPrimary = Color(0xFF1A1A1A); // Very dark gray for primary
  static const darkOnPrimary = Color(0xFFFFFFFF); // White text on primary
  static const darkPrimaryContainer = Color(0xFFF0F0F0); // Light gray container
  static const darkOnPrimaryContainer = Color(0xFF1A1A1A); // Very dark gray text
  static const darkSecondary = Color(0xFF4A90E2); // Blue for secondary elements
  static const darkOnSecondary = Color(0xFFFFFFFF); // White text
  static const darkTertiary = Color(0xFF50C878); // Green for tertiary elements
  static const darkOnTertiary = Color(0xFFFFFFFF); // White text
  static const darkError = Color(0xFFE53E3E); // Red for errors
  static const darkOnError = Color(0xFFFFFFFF); // White text
  static const darkErrorContainer = Color(0xFFFFEBEE); // Light red background
  static const darkOnErrorContainer = Color(0xFFE53E3E); // Red text
  static const darkInversePrimary = Color(0xFFCCCCCC); // Light gray
  static const darkShadow = Color(0xFF000000); // Black shadow
  static const darkSurface = Color(0xFFFFFFFF); // White background
  static const darkOnSurface = Color(0xFF1A1A1A); // Very dark gray text for better contrast
  static const darkAppBarBackground = Color(0xFFFFFFFF); // White app bar
  static const darkAccent = Color(0xFF4A90E2); // Blue accent
  static const darkCardBackground = Color(0xFFFFFFFF); // White cards
  static const darkBorderColor = Color(0xFFE0E0E0); // Light gray borders
  static const darkTextPrimary = Color(0xFF1A1A1A); // Very dark gray for primary text
  static const darkTextSecondary = Color(0xFF666666); // Medium gray for secondary text
  static const darkTextHint = Color(0xFF999999); // Light gray for hint text
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

// Helper function to create Gilroy text style
TextStyle _gilroyTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    fontFamily: 'Gilroy',
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontStyle: fontStyle,
  );
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: _gilroyTextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightModeColors.lightPrimary,
      foregroundColor: LightModeColors.lightOnPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: _gilroyTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LightModeColors.lightPrimary,
      side: BorderSide(color: LightModeColors.lightPrimary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
  ),
  cardTheme: CardThemeData(
    color: LightModeColors.lightCardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LightModeColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: LightModeColors.lightBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: LightModeColors.lightBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: LightModeColors.lightPrimary, width: 2),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: _gilroyTextStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: _gilroyTextStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: _gilroyTextStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: _gilroyTextStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: _gilroyTextStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: _gilroyTextStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: _gilroyTextStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: _gilroyTextStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: _gilroyTextStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: _gilroyTextStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: _gilroyTextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: _gilroyTextStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: _gilroyTextStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: _gilroyTextStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: _gilroyTextStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: _gilroyTextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: DarkModeColors.darkOnSurface,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkModeColors.darkPrimary,
      foregroundColor: DarkModeColors.darkOnPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: _gilroyTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DarkModeColors.darkPrimary,
      side: BorderSide(color: DarkModeColors.darkPrimary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
  ),
  cardTheme: CardThemeData(
    color: DarkModeColors.darkCardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkModeColors.darkCardBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DarkModeColors.darkBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DarkModeColors.darkBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DarkModeColors.darkPrimary, width: 2),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: _gilroyTextStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: _gilroyTextStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: _gilroyTextStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: _gilroyTextStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: _gilroyTextStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: _gilroyTextStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: _gilroyTextStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: _gilroyTextStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: _gilroyTextStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: _gilroyTextStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: _gilroyTextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: _gilroyTextStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: _gilroyTextStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: _gilroyTextStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: _gilroyTextStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);
