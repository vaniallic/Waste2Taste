import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colours, taken from the Waste2Taste Figma design.
class W2T {
  static const rust = Color(0xFFA0361B);
  static const rustDark = Color(0xFF66261A);
  static const rustSoft = Color(0xFFB24A2A);
  static const butter = Color(0xFFF4DA9E);
  static const cream = Color(0xFFFBEFD0);
  static const olive = Color(0xFF46552A);
  static const ink = Color(0xFF3E4A22);
  static const muted = Color(0xFF6B735F);
  static const brownText = Color(0xFF7A3A22);
  static const danger = Color(0xFFB3261E);
  static const oliveSoft = Color(0xFFDCE5C6);
  static const rustTint = Color(0xFFF8DCCF);
  static const divider = Color(0xFFD7A27F);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: W2T.rust, primary: W2T.olive, secondary: W2T.rust, surface: W2T.butter),
    scaffoldBackgroundColor: W2T.butter,
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: W2T.ink, displayColor: W2T.olive);
  return base.copyWith(
    textTheme: text,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: W2T.olive,
        foregroundColor: W2T.butter,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: W2T.rust, width: 1.5)),
    ),
  );
}

/// Heading text style used across screens.
TextStyle heading(double size, {Color color = W2T.olive}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5, height: 1.15);
