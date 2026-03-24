import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF05e265);
  static const Color darkBg = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1a1a1a);
  
  static const Color lightBg = Colors.white;
  static const Color lightCard = Color(0xFFF0F4F8); // Un gris muy ligero para las tarjetas sobre fondo blanco

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: lightBg,
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: Colors.black,
      surfaceContainerHighest: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Colors.black12),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: darkBg,
    cardColor: darkCard,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      surface: darkCard,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Colors.white24),
  );
}
