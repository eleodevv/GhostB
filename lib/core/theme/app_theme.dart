import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema basado en la mascota pixel ghost — blanco, negro, grises, pixel-clean.
class AppTheme {
  AppTheme._();

  // Palette — inspirada en el icono (blanco, negro, gris)
  static const Color ghost = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF6B6B6B);
  static const Color greyLight = Color(0xFFB0B0B0);
  static const Color greyBg = Color(0xFFF5F5F5);
  static const Color accent = Color(0xFF4A4A4A);
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerSoft = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFE65100);

  // Dark
  static const Color inkDark = Color(0xFFF0F0F0);
  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color greyDark = Color(0xFF888888);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: isLight ? greyBg : bgDark,
      colorScheme: ColorScheme(
        brightness: b,
        primary: isLight ? ink : inkDark,
        onPrimary: isLight ? ghost : bgDark,
        surface: isLight ? ghost : surfaceDark,
        onSurface: isLight ? ink : inkDark,
        secondary: isLight ? grey : greyDark,
        onSecondary: isLight ? ink : inkDark,
        error: danger,
        onError: ghost,
        outline: isLight ? const Color(0xFFE0E0E0) : borderDark,
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(TextTheme(
        displayLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: isLight ? ink : inkDark, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: isLight ? ink : inkDark),
        titleMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isLight ? ink : inkDark),
        bodyLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
            color: isLight ? ink : inkDark),
        bodyMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w400,
            color: isLight ? grey : greyDark),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
            color: isLight ? greyLight : greyDark),
      )),
    );
  }
}
