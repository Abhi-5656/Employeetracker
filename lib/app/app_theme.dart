import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF667EEA),
    brightness: Brightness.light,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),

    // ✅ Your Flutter version expects CardThemeData here
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}