import 'package:flutter/material.dart';

class AppColors {
  // Tigo Brand Colors
  static const Color primary = Color(0xFF00377B); // Tigo Deep Blue
  static const Color primaryDark = Color(0xFF001F4D); // Tigo Darker Blue (from Login)
  static const Color primaryLight = Color(0xFF00C8FF); // Tigo Cyan
  static const Color accent = Color(0xFFFFC800); // Tigo Yellow
  
  // Neutral Colors
  static const Color secondary = Color(0xFF546E7A); // Blue Grey
  static const Color bgLight = Color(0xFFF4F6F9); // Very Light Blue-Grey
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF101828); // Dark Blue-Grey
  static const Color textMuted = Color(0xFF667085); // Medium Grey

  // Status Badge Colors (Pastel/Modern)
  static const Color statusRegistradaBg = Color(0xFFF2F4F7);
  static const Color statusRegistradaText = Color(0xFF344054);
  
  static const Color statusEnValidacionBg = Color(0xFFFEF3F2);
  static const Color statusEnValidacionText = Color(0xFFB42318);
  
  static const Color statusProgramadaBg = Color(0xFFEFF8FF);
  static const Color statusProgramadaText = Color(0xFF175CD3);
  
  static const Color statusEjecucionBg = Color(0xFFECFDF3);
  static const Color statusEjecucionText = Color(0xFF027A48);
  
  static const Color statusEvidenciasBg = Color(0xFFF0F9FF); // Light Cyan
  static const Color statusEvidenciasText = Color(0xFF026AA2);
  
  static const Color statusCerradaBg = Color(0xFFF9FAFB);
  static const Color statusCerradaText = Color(0xFF344054);
  
  static const Color statusRechazadaBg = Color(0xFFFEF3F2);
  static const Color statusRechazadaText = Color(0xFFB42318);
  
  static const Color statusDevueltaBg = Color(0xFFFFFAEB);
  static const Color statusDevueltaText = Color(0xFFB54708);
}

// ignore_for_file: deprecated_member_use
extension ColorExtension on Color {
  Color withOpacitySafe(double opacity) {
    final int alpha = (255 * opacity).round();
    final int red = (value >> 16) & 0xFF;
    final int green = (value >> 8) & 0xFF;
    final int blue = value & 0xFF;
    return Color.fromARGB(alpha, red, green, blue);
  }
}