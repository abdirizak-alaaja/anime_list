import 'package:flutter/material.dart';

/// Palette modelled on MyAnimeList's light and dark site themes.
abstract final class AppColors {
  // Brand blues.
  static const malBlue = Color(0xFF2E51A2);
  static const malBlueLight = Color(0xFF4F74C8);
  static const malBlueOnDark = Color(0xFF8AA6E6);
  static const malBlueTint = Color(0xFFE1E7F5);

  // Light theme surfaces.
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF6F6F6);
  static const lightSurfaceHigh = Color(0xFFEDEFF5);
  static const lightBorder = Color(0xFFD8D8D8);
  static const lightText = Color(0xFF323232);
  static const lightTextMuted = Color(0xFF6B6B6B);

  // Dark theme surfaces.
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF181818);
  static const darkSurfaceHigh = Color(0xFF242424);
  static const darkBorder = Color(0xFF2F2F2F);
  static const darkText = Color(0xFFE6E6E6);
  static const darkTextMuted = Color(0xFFA0A0A0);

  // Accents.
  static const score = Color(0xFFF1C40F);
  static const favorite = Color(0xFFE0457B);
  static const error = Color(0xFFD64545);

  // MyAnimeList list-status colors.
  static const watching = Color(0xFF2DB039);
  static const completed = Color(0xFF26448F);
  static const completedOnDark = Color(0xFF5B7FD1);
  static const onHold = Color(0xFFF9D457);
  static const dropped = Color(0xFFA12F31);
  static const droppedOnDark = Color(0xFFD0484A);
  static const planToWatch = Color(0xFFC3C3C3);
  static const planToWatchOnLight = Color(0xFF8E8E8E);
}
