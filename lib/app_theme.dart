import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0D13);
  static const bg2 = Color(0xFF11131A);
  static const panel = Color(0xFF171A24);
  static const panel2 = Color(0xFF1D2130);
  static const field = Color(0xFF121620);
  static const border = Color(0xFF2A3040);
  static const text = Color(0xFFF4F7FB);
  static const muted = Color(0xFF9BA3B4);
  static const cyan = Color(0xFF46D9FF);
  static const violet = Color(0xFFB98CFF);
  static const amber = Color(0xFFFFB84D);
  static const coral = Color(0xFFFF5C7A);
}

BoxDecoration panelDecoration({
  Color color = AppColors.panel,
  double radius = 26,
}) {
  return BoxDecoration(
    color: color.withValues(alpha: 0.88),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.cyan.withValues(alpha: 0.04),
        blurRadius: 30,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

InputDecoration fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.field,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide.none,
    ),
  );
}

SizedBox gap([double height = 18]) => SizedBox(height: height);
