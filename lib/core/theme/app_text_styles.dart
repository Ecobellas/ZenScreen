import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Space Grotesk styles for modern minimal typography
  static TextStyle get headingLarge => GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      );
  static TextStyle get headingMedium => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );
  static TextStyle get headingSmall => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );
  static TextStyle get bodyLarge => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );
  static TextStyle get bodyMedium => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: AppColors.textSecondary,
      );
  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textHint,
      );
  static TextStyle get labelLarge => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );
  static TextStyle get labelMedium => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: AppColors.textSecondary,
      );
  static TextStyle get labelSmall => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  // Space Grotesk for metrics/numbers as well
  static TextStyle get metricLarge => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        letterSpacing: -2.0,
        color: AppColors.textPrimary,
      );
  static TextStyle get metricMedium => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );
  static TextStyle get metricSmall => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: AppColors.textSecondary,
      );
}
