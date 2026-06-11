import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors — derived from logo's cyan→violet→pink palette
  static const Color backgroundColor = Color(0xFF06060F); // Deep navy-black (logo bg)
  static const Color surfaceColor = Color(0xFF12121E); // Elevated dark navy
  static const Color cardColor = Color(0xFF1C1C2E); // Card surface
  
  static const Color primaryColor = Color(0xFFA855F7); // Vibrant Violet (logo center)
  static const Color secondaryColor = Color(0xFF00D4FF); // Neon Cyan (logo top)
  static const Color accentPink = Color(0xFFEC4899); // Hot Pink (logo bottom)
  static const Color accentRed = Color(0xFFEF4444); // Red for LIVE badges
  
  static const Color textPrimary = Color(0xFFF0F0FF); // Soft white with slight blue tint
  static const Color textSecondary = Color(0xFF9B9BB5); // Lavender grey
  static const Color textMuted = Color(0xFF5E5E7A); // Muted slate

  // Gradient definitions — matches logo's flowing gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFFA855F7), Color(0xFFEC4899)], // Cyan → Violet → Pink
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)], // Violet → Pink
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    colors: [Colors.transparent, backgroundColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.3, 1.0],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: accentRed,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
