import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Updated colors to match the Surge brand
  static const Color surgeColor = Color(0xFFAF97CD); // Purple from design
  static const Color surgeLightColor = Color(0xFFF3F0FF); // Light purple background
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtitleColor = Color(0xFF6B7280);
  static const Color greenColor = Color(0xFF06754B);
  static const Color yellowColor = Color(0xFFF59E0B);
  static const Color blueColor = Color(0xFF1C5DE1);
  static const Color redColor = Color(0xFFCD1B1B);
  static const Color lightGrayColor = Color(0xFFF1F5F9);
  static const Color darkGrayColor = Color(0xFF334155);

  // Preload fonts to avoid runtime issues
  static Future<void> preloadFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.poppins(),
        GoogleFonts.poppins(fontWeight: FontWeight.w400),
        GoogleFonts.poppins(fontWeight: FontWeight.w600),
        GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ]);
    } catch (e) {
      print('Failed to preload fonts: $e');
      // Fallback to system fonts if Google Fonts fail
    }
  }

  static ThemeData get theme {
    // Use a fallback approach for fonts
    TextStyle _getTextStyle({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
    }) {
      try {
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      } catch (e) {
        // Fallback to system font if Google Fonts fail
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: 'Roboto', // Android default
        );
      }
    }

    String? _getFontFamily() {
      try {
        return GoogleFonts.poppins().fontFamily;
      } catch (e) {
        return 'Roboto'; // Fallback to system font
      }
    }

    return ThemeData(
      primarySwatch: Colors.purple,
      primaryColor: surgeColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: _getFontFamily(),
      appBarTheme: AppBarTheme(
        backgroundColor: surgeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: _getTextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardTheme(
        color: cardColor,
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surgeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: _getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surgeColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: _getTextStyle(
          color: subtitleColor,
          fontSize: 14,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: _getTextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineMedium: _getTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: _getTextStyle(
          fontSize: 16,
          color: textColor,
        ),
        bodyMedium: _getTextStyle(
          fontSize: 14,
          color: subtitleColor,
        ),
      ),
    );
  }
}