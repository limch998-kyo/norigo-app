import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors (matching web theme — Blue-600 system)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryForeground = Colors.white;

  /// Tracks current dark mode state. Updated by NorigoApp when theme changes.
  static bool isDark = false;

  // Light theme constants (used in lightTheme definition)
  static const Color _lightPrimaryBg = Color(0xFFEFF6FF);
  static const Color _lightBackground = Colors.white;
  static const Color _lightForeground = Color(0xFF0F172A);
  static const Color _lightMuted = Color(0xFFF8FAFC);
  static const Color _lightMutedForeground = Color(0xFF64748B);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightCard = Colors.white;

  // Dynamic getters — adapt to current theme mode
  static Color get primaryBg => isDark ? const Color(0xFF1E3A5F) : _lightPrimaryBg;
  static Color get background => isDark ? _darkBackground : _lightBackground;
  static Color get foreground => isDark ? _darkForeground : _lightForeground;
  static Color get muted => isDark ? _darkMuted : _lightMuted;
  static Color get mutedForeground => isDark ? _darkMutedForeground : _lightMutedForeground;
  static Color get border => isDark ? const Color(0xFF333333) : _lightBorder;
  static Color get card => isDark ? _darkCard : _lightCard;
  static const Color destructive = Color(0xFFEF4444);

  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFF97316);
  static const Color amber = Color(0xFFD97706);

  static const String _fontFamily = 'Inter';

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        primaryContainer: primaryLight,
        onPrimaryContainer: primary,
        secondary: _lightMuted,
        onSecondary: _lightForeground,
        surface: _lightBackground,
        onSurface: _lightForeground,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        outline: _lightBorder,
        error: destructive,
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: base.textTheme.apply(
        fontFamily: _fontFamily,
        bodyColor: _lightForeground,
        displayColor: _lightForeground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: _lightForeground,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightForeground,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightForeground,
          side: const BorderSide(color: _lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: _lightMutedForeground,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightMuted,
        selectedColor: primary,
        secondarySelectedColor: primary,
        labelStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 13, color: _lightForeground),
        secondaryLabelStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 13, color: primaryForeground),
        side: const BorderSide(color: _lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        showCheckmark: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightBackground,
        selectedItemColor: primary,
        unselectedItemColor: _lightMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        elevation: 2,
      ),
    );
  }

  // Dark mode colors
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkForeground = Color(0xFFFAFAFA);
  static const Color _darkPrimary = Color(0xFFE5E5E5);
  static const Color _darkPrimaryForeground = Color(0xFF171717);
  static const Color _darkBorder = Color(0x1AFFFFFF);
  static const Color _darkCard = Color(0xFF171717);
  static const Color _darkMuted = Color(0xFF262626);
  static const Color _darkMutedForeground = Color(0xFFA3A3A3);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: primaryForeground,
        primaryContainer: Color(0xFF1E3A5F),
        onPrimaryContainer: _darkPrimary,
        secondary: _darkMuted,
        onSecondary: _darkForeground,
        surface: _darkBackground,
        onSurface: _darkForeground,
        surfaceContainerHighest: Color(0xFF1C1C1C),
        outline: _darkBorder,
        error: destructive,
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: base.textTheme.apply(
        fontFamily: _fontFamily,
        bodyColor: _darkForeground,
        displayColor: _darkForeground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _darkForeground,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkForeground,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkForeground,
          side: const BorderSide(color: _darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: _darkMutedForeground,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkMuted,
        selectedColor: primary,
        secondarySelectedColor: primary,
        labelStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 13, color: _darkForeground),
        secondaryLabelStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 13, color: primaryForeground),
        side: const BorderSide(color: _darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        showCheckmark: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: primary,
        unselectedItemColor: _darkMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        elevation: 2,
      ),
    );
  }
}
