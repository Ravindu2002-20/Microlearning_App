import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
          surface: AppColors.surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide.none,
          ),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.surfaceDark),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundDark,
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          surface: AppColors.surfaceLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(color: AppColors.textSecondaryLight.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.1),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundLight,
        ),
      );

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(color: primary, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: primary, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: primary, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: primary),
      bodyMedium: TextStyle(color: secondary),
      labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: secondary),
    );
  }
}

