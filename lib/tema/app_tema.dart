import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vizuelni identitet aplikacije - boje, fontovi, Material 3 tema.
class AppTema {
  AppTema._();

  /// Glavna (primarna) boja aplikacije - moderna ljubičasto-plava.
  static const Color primarna = Color(0xFF6C5CE7);
  static const Color primarnaTamna = Color(0xFF5541D7);
  static const Color akcenat = Color(0xFF00D2A8);

  static const Color pozadina = Color(0xFFF5F6FA);
  static const Color povrsina = Colors.white;

  static const Color tekstTamni = Color(0xFF1E1E2C);
  static const Color tekstSivi = Color(0xFF8E8E9A);

  static const Color uspjeh = Color(0xFF00C27A);
  static const Color upozorenje = Color(0xFFFFA726);
  static const Color greska = Color(0xFFEF5350);

  /// Svijetla tema aplikacije.
  static ThemeData get svijetla {
    final baznaTema = ThemeData.light(useMaterial3: true);

    return baznaTema.copyWith(
      scaffoldBackgroundColor: pozadina,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarna,
        primary: primarna,
        secondary: akcenat,
        surface: povrsina,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baznaTema.textTheme).apply(
        bodyColor: tekstTamni,
        displayColor: tekstTamni,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pozadina,
        elevation: 0,
        centerTitle: false,
        foregroundColor: tekstTamni,
        titleTextStyle: TextStyle(
          color: tekstTamni,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: povrsina,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pozadina,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primarna, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarna,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primarna,
        foregroundColor: Colors.white,
      ),
    );
  }
}
