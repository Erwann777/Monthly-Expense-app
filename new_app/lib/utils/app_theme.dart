import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ───
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMid = Color(0xFF16213E);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color backgroundGradientStart = Color(0xFF667EEA);
  static const Color backgroundGradientEnd = Color(0xFF764BA2);

  // Dark theme colors
  static const Color darkBg = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF222240);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);

  // ─── Gradient Definitions ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Border Radius ───
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 100.0;

  // ─── Spacing ───
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Glassmorphism Decorator ───
  static BoxDecoration glassDecoration({
    bool isDark = false,
    double opacity = 0.1,
    double borderRadius = radiusXxl,
    double blurRadius = 20.0,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: opacity * 0.5)
          : Colors.white.withValues(alpha: 0.7 + opacity * 0.3),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
          blurRadius: blurRadius,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ─── Neumorphism Decorator ───
  static BoxDecoration neumorphicDecoration({
    bool isDark = false,
    double borderRadius = radiusXxl,
  }) {
    final bgColor = isDark ? darkCard : Colors.white;
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.08),
          offset: const Offset(4, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
      ],
    );
  }

  // ─── Light Theme ───
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentPurple,
      brightness: Brightness.light,
      primary: accentPurple,
      secondary: accentBlue,
      tertiary: accentTeal,
      surface: surfaceLight,
      error: errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLight,
      textTheme: _buildTextTheme(false),
      appBarTheme: _buildAppBarTheme(false),
      cardTheme: _buildCardTheme(false),
      inputDecorationTheme: _buildInputTheme(false),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      floatingActionButtonTheme: _buildFabTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  // ─── Dark Theme ───
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentPurple,
      brightness: Brightness.dark,
      primary: accentPurple,
      secondary: accentBlue,
      tertiary: accentTeal,
      surface: darkBg,
      error: errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      textTheme: _buildTextTheme(true),
      appBarTheme: _buildAppBarTheme(true),
      cardTheme: _buildCardTheme(true),
      inputDecorationTheme: _buildInputTheme(true),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      floatingActionButtonTheme: _buildFabTheme(),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: accentPurple,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1, space: 1),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final c1 = isDark ? darkText : textPrimary;
    final c2 = isDark ? darkTextSecondary : textSecondary;
    final c3 = isDark ? const Color(0xFF64748B) : textMuted;
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: c1, letterSpacing: -1.0),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: c1, letterSpacing: -0.5),
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: c1),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: c1),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: c1),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c1),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c1),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: c1),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: c2),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: c3),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c1),
    );
  }

  static AppBarTheme _buildAppBarTheme(bool isDark) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? darkText : textPrimary,
      ),
      iconTheme: IconThemeData(color: isDark ? darkText : textPrimary),
    );
  }

  static CardThemeData _buildCardTheme(bool isDark) {
    return CardThemeData(
      elevation: 0,
      color: isDark ? darkCard : surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: BorderSide(
          color: isDark
              ? darkDivider.withValues(alpha: 0.3)
              : divider.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E36) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingMd),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: accentPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: isDark ? darkTextSecondary : textSecondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(
        color: isDark ? const Color(0xFF475569) : textMuted,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentPurple,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        side: const BorderSide(color: accentPurple, width: 1.5),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPurple,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: accentPurple,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: surfaceCard,
      selectedItemColor: accentPurple,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
    );
  }
}
