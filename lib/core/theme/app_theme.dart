import 'package:flutter/material.dart';
import '../constants/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — Complete ThemeData for Light & Dark modes
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Light Theme ───────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
        ),

        // ── AppBar ──
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimaryLight,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        // ── Text ──
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.05,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.05,
            letterSpacing: -0.3,
          ),
          displaySmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.08,
            letterSpacing: -0.2,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
            height: 1.15,
          ),
          headlineMedium: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
            height: 1.2,
          ),
          headlineSmall: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
            height: 1.25,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryLight,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
            height: 1.3,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
            height: 1.3,
          ),
        ),

        // ── Cards ──
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        // ── Elevated Button ──
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ── Filled Button ──
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ── Input Decoration ──
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColors.textSecondaryLight.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.primaryLight,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.error,
            ),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
          ),
        ),

        // ── Bottom Navigation ──
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: AppColors.backgroundLight,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textSecondaryLight,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),

        // ── Snackbar ──
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),

        // ── Divider ──
        dividerTheme: DividerThemeData(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.15),
          thickness: 1,
          space: 1,
        ),
      );

  // ── Dark Theme ────────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
        ),

        // ── AppBar ──
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimaryDark,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        // ── Text ──
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            height: 1.05,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            height: 1.05,
            letterSpacing: -0.3,
          ),
          displaySmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            height: 1.08,
            letterSpacing: -0.2,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
            height: 1.15,
          ),
          headlineMedium: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
            height: 1.2,
          ),
          headlineSmall: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
            height: 1.25,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryDark,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryDark,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryDark,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
            height: 1.3,
          ),
          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryDark,
            height: 1.3,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryDark,
            height: 1.3,
          ),
        ),

        // ── Cards ──
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        // ── Elevated Button ──
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ── Filled Button ──
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ── Input Decoration ──
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: AppColors.textSecondaryDark.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.primaryDark,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.error,
            ),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
          ),
        ),

        // ── Bottom Navigation ──
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: AppColors.backgroundDark,
          selectedItemColor: AppColors.primaryDark,
          unselectedItemColor: AppColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),

        // ── Snackbar ──
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),

        // ── Divider ──
        dividerTheme: DividerThemeData(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.15),
          thickness: 1,
          space: 1,
        ),
      );
}