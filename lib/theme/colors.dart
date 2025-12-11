import 'package:flutter/material.dart';

class AppColors {
  // Palette: primary teal, black/white, red for delete/error
  static const Color primary = Color(0xFF0097B2);
  static const Color accent = primary;

  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Colors.black;

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF111111);

  static const Color textPrimaryLight = Colors.black;
  static const Color textSecondaryLight = Colors.black54;

  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;

  static const Color success = primary; // reuse primary for positive states
  static const Color error = Color(0xFFFF3B30);
}
