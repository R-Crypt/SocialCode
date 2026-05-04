import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (Brutalist Palette)
  static const Color primaryMagenta = Color(0xFFE91E63); // High-Impact Pink
  static const Color accentPurple = Color(0xFF9C27B0); // Logo Purple
  static const Color backgroundLight = Color(0xFFF9F9F9); // Off-white Paper
  static const Color borderBlack = Color(0xFF111111); // Sharp Black
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static ThemeData get brutalistTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryMagenta,
        secondary: borderBlack,
        surface: surfaceWhite,
        onSurface: borderBlack,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: borderBlack,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: borderBlack,
        ),
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: borderBlack,
          letterSpacing: 1.0,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: borderBlack.withOpacity(0.9),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: borderBlack),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: borderBlack,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: borderBlack,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Square corners
            side: const BorderSide(color: borderBlack, width: 2),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // Sharp Brutalist corners
          side: const BorderSide(color: borderBlack, width: 1.5),
        ),
      ),
    );
  }
}
