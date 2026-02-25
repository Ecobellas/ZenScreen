import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds: Clean, deep minimal dark mode
  static const background = Color(0xFF000000); // Pure deep black
  static const surface = Color(0xFF0E0E11); // Extremely dark, barely grey
  static const card = Color(0xFF15151A); // Slightly raised card

  // Brand: Minimalist chic aesthetic
  static const primary = Color(0xFFFAFAFA); // Crisp off-white for primary accents
  static const secondary = Color(0xFF8A8A93); // Soft, muted tertiary color
  static const error = Color(0xFFFF453A); // iOS-like crisp error red

  // Text
  static const textPrimary = Color(0xFFFFFFFF); // High contrast text
  static const textSecondary = Color(0xFF8A8A93); // Refined secondary text
  static const textHint = Color(0xFF48484A); // Muted hint
  static const textInverse = Color(0xFF000000); // For dark text on light elements

  // Utility
  static const divider = Color(0xFF232326); // Subtle borders
  static const shimmer = Color(0xFF1F1F24); // Shimmer matching card
}
