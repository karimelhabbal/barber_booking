import 'package:flutter/material.dart';

abstract final class AppColors {
  // Stitch Design System
  static const background = Color(0xFF111418);
  static const surface = Color(0xFF191C20);
  static const surface2 = Color(0xFF1D2024);
  static const surface3 = Color(0xFF272A2E);
  static const surfaceHigh = Color(0xFF323539);

  static const primary = Color(0xFFC89B53);
  static const primaryHover = Color(0xFFB88746);
  static const primarySoft = Color(0x26C89B53);
  static const primaryHighlight = Color(0xFFEFBF73);

  static const text = Color(0xFFE1E2E8);
  static const textSecondary = Color(0xFFD3C4B3);
  static const outline = Color(0xFF9B8F7F);
  static const outlineVariant = Color(0xFF4F4538);

  static const success = Color(0xFF2E7D5B);
  static const pending = Color(0xFFED8936);
  static const error = Color(0xFFD32F2F);
}

abstract final class AppTheme {
  static ThemeData light() {
    return _buildTheme(
      brightness: Brightness.light,
      background: const Color(0xFFF7F4EF),
      surface: const Color(0xFFFFFDFC),
      surface2: const Color(0xFFF1ECE4),
      surface3: const Color(0xFFE8E0D4),
      surfaceHigh: const Color(0xFFDDD1C0),
      text: const Color(0xFF25272C),
      textSecondary: const Color(0xFF665A4C),
      outline: const Color(0xFF817466),
      outlineVariant: const Color(0xFFCFC2B1),
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.background,
      surface: AppColors.surface,
      surface2: AppColors.surface2,
      surface3: AppColors.surface3,
      surfaceHigh: AppColors.surfaceHigh,
      text: AppColors.text,
      textSecondary: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surface2,
    required Color surface3,
    required Color surfaceHigh,
    required Color text,
    required Color textSecondary,
    required Color outline,
    required Color outlineVariant,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,

      // Brand
      primary: AppColors.primary,
      onPrimary: AppColors.background,

      secondary: AppColors.primaryHighlight,
      onSecondary: AppColors.background,

      // Feedback
      error: AppColors.error,
      onError: Colors.white,

      // Surfaces
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceHigh,

      // Secondary semantic text/icons
      onSurfaceVariant: textSecondary,

      // Borders
      outline: outline,
      outlineVariant: outlineVariant,
    );

    final textTheme = _textTheme(text, textSecondary);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,

      // App background
      scaffoldBackgroundColor: background,
      canvasColor: background,

      // Typography
      textTheme: textTheme,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // Primary buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryHighlight,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: outlineVariant),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(outlineVariant),
        enabledBorder: _inputBorder(outlineVariant),
        focusedBorder: _inputBorder(AppColors.primary),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryHighlight,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: surface3,
        selectedColor: AppColors.primarySoft,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // Icons
      iconTheme: IconThemeData(color: textSecondary),

      // Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primaryHighlight,
        selectionColor: AppColors.primarySoft,
        selectionHandleColor: AppColors.primary,
      ),

      // No extra theme extensions.
      extensions: const <ThemeExtension<dynamic>>[],
    );
  }

  static TextTheme _textTheme(Color text, Color textSecondary) {
    return TextTheme(
      displayLarge: TextStyle(
        color: text,
        fontSize: 36,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: text,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: text,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }
}
