import 'package:flutter/material.dart';

/// Central color palette for the app — vibrant, modern, flat design.
abstract final class AppColors {
  // === Brand Palette ===
  static const primary = Color(0xFF6C63FF); // Electric Violet
  static const primaryDark = Color(0xFF4B44CC);
  static const secondary = Color(0xFF00C9A7); // Mint Green
  static const accent = Color(0xFFFF6584); // Coral Pink
  static const warning = Color(0xFFFFB547); // Amber Yellow
  static const info = Color(0xFF00B4D8); // Cyan Blue

  // === Light Surface ===
  static const surfaceLight = Color(0xFFF0F2FF);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE4E6F3);

  // === Dark Surface ===
  static const surfaceDark = Color(0xFF0E0E1A);
  static const cardDark = Color(0xFF181828);
  static const borderDark = Color(0xFF2A2A40);

  // === Tag / Badge Gradients ===
  static const List<Color> gradientPurple = [
    Color(0xFF6C63FF),
    Color(0xFF9B8FFF),
  ];
  static const List<Color> gradientTeal = [
    Color(0xFF00C9A7),
    Color(0xFF00E5CC),
  ];
  static const List<Color> gradientCoral = [
    Color(0xFFFF6584),
    Color(0xFFFF8FA3),
  ];
  static const List<Color> gradientAmber = [
    Color(0xFFFFB547),
    Color(0xFFFFCF80),
  ];
  static const List<Color> gradientCyan = [
    Color(0xFF00B4D8),
    Color(0xFF48D6F5),
  ];
  static const List<Color> gradientIndigo = [
    Color(0xFF3B5BDB),
    Color(0xFF748FFC),
  ];
  static const List<Color> gradientGreen = [
    Color(0xFF2ECC71),
    Color(0xFF55EFC4),
  ];
  static const List<Color> gradientOrange = [
    Color(0xFFE17055),
    Color(0xFFFF7675),
  ];

  // === Avatar color pool — cycles by user ID ===
  static const List<List<Color>> avatarGradients = [
    gradientPurple,
    gradientTeal,
    gradientCoral,
    gradientAmber,
    gradientCyan,
    gradientIndigo,
    gradientGreen,
    gradientOrange,
  ];

  static List<Color> avatarGradientFor(int id) =>
      avatarGradients[id % avatarGradients.length];
}
