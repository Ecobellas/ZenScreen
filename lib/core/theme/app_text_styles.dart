import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Inter styles for modern minimal typography
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      );
  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );
  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: AppColors.textSecondary,
      );
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textHint,
      );
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: AppColors.textSecondary,
      );

  // JetBrains Mono for metrics/numbers, adding a chic tech vibe
  static TextStyle get metricLarge => GoogleFonts.jetBrainsMono(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        letterSpacing: -2.0,
        color: AppColors.textPrimary,
      );
  static TextStyle get metricMedium => GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );
  static TextStyle get metricSmall => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: AppColors.textSecondary,
      );
}
