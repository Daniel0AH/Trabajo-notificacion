import 'package:flutter/material.dart';

const primaryCream = Color(0xFFF4EBDD);
const ink = Color(0xFF29261F);
const terracotta = Color(0xFFB85C38);
const sage = Color(0xFF6D8061);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: terracotta).copyWith(
    primary: terracotta,
    onPrimary: Colors.white,
    surface: const Color(0xFFFFFCF7),
    onSurface: ink,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: primaryCream,
    useMaterial3: true,
    fontFamily: 'Georgia',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryCream,
      foregroundColor: ink,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFCF7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
