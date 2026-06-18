import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A365D);
  static const Color accent = Color(0xFFFFC107);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
      scaffoldBackgroundColor: Colors.grey[50],
      // card styling via cardColor and shapes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
      scaffoldBackgroundColor: Colors.grey[900],
      // card styling via cardColor and shapes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
    );
  }
}
