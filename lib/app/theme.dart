import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Premium Blue + Gold + White Palette ──────────────────────────────
  static const Color royalBlue    = Color(0xFF1A237E); // Deep Royal Blue
  static const Color navyBlue     = Color(0xFF283593); // NavBar / AppBar
  static const Color skyBlue      = Color(0xFF3F51B5); // Highlights
  static const Color lightBlue    = Color(0xFFE8EAF6); // Backgrounds
  static const Color gold         = Color(0xFFD6A51D); // Accent Gold
  static const Color deepGold     = Color(0xFF9A7300); // Deep Gold
  static const Color softGold     = Color(0xFFFFF8E1); // Light Gold Tint
  static const Color white        = Color(0xFFFFFFFF);
  static const Color offWhite     = Color(0xFFF5F7FF);
  static const Color darkText     = Color(0xFF0D1347);
  static const Color greyText     = Color(0xFF757575);
  static const Color errorRed     = Color(0xFFD32F2F);
  static const Color success      = Color(0xFF2E7D32);

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: royalBlue,
        onPrimary: white,
        secondary: gold,
        onSecondary: darkText,
        surface: white,
        onSurface: darkText,
        surfaceContainerHighest: lightBlue,
        error: errorRed,
      ),
      scaffoldBackgroundColor: offWhite,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        bodyLarge: const TextStyle(color: darkText),
        bodyMedium: const TextStyle(color: darkText),
        bodySmall: const TextStyle(color: greyText),
        titleLarge: const TextStyle(color: darkText, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: darkText, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: royalBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: darkText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 4,
          shadowColor: gold.withOpacity(0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: royalBlue,
          side: const BorderSide(color: royalBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBlue.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBBBEEE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: royalBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: greyText),
        prefixIconColor: gold,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 3,
        shadowColor: royalBlue.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: royalBlue,
        unselectedItemColor: greyText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        elevation: 16,
      ),
      dividerTheme: const DividerThemeData(color: lightBlue, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: darkText,
        elevation: 6,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBlue,
        labelStyle: const TextStyle(color: royalBlue, fontWeight: FontWeight.w600, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
