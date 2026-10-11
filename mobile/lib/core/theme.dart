import 'package:flutter/material.dart';

import 'colors.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.lightBlue,
    onSecondary: AppColors.navy,
    surface: Colors.white,
    onSurface: AppColors.navy,
    error: AppColors.danger,
    onError: Colors.white,
    outline: AppColors.line,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    visualDensity: VisualDensity.standard,
  );
}

/// Dekorasi input seragam (tanpa bergantung pada InputDecorationTheme agar kompatibel antar versi Flutter).
InputDecoration appInput(String? label, {String? hint, Widget? prefix, Widget? suffix, String? errorText}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.navy, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.6),
  );
}

BoxDecoration cardDecoration({Color color = Colors.white, double radius = 16}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.line),
    );
