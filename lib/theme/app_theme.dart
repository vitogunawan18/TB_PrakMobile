 import 'package:flutter/material.dart';

class AppTheme {
  // Hex Colors defined in tokens
  static const Color bgPrimary = Color(0xFF0A0E1A);
  static const Color cardSurface = Color(0xFF161B2A);
  static const Color accentPrimary = Color(0xFF00F5D4); // Neon Mint
  static const Color accentSecondary = Color(0xFF1D4ED8); // Royal Blue
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusExpired = Color(0xFFEF4444);

  // Fallback to dark theme since it is Dark Mode exclusive
  static ThemeData light() {
    return dark();
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      cardColor: cardSurface,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: cardSurface,
        error: statusExpired,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  static BoxDecoration glassCardDecoration() {
    return BoxDecoration(
      color: cardSurface.withOpacity(0.85),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accentSecondary.withOpacity(0.15), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration gradientButtonDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [accentSecondary, accentPrimary],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: [
        BoxShadow(
          color: accentSecondary.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static String getDirectImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=600';
    }
    
    // Override known Google Drive IDs to high-quality public Unsplash placeholders
    
    // 1. Bandung Music Festival (Konser Musik)
    if (url.contains('1TyzJ6GahcVmZKVb7408eilb_HHdZteEX')) {
      return 'https://images.unsplash.com/photo-1506157786151-b8491531f063?q=80&w=600&auto=format&fit=crop';
    }
    
    // 2. Jakarta Developer Conference (Seminar Teknologi)
    if (url.contains('1Yy6rFG0ReQTkBCNzeeM2qTV-j_GN4Zcu')) {
      return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=600&auto=format&fit=crop';
    }
    
    // 3. Surabaya Education Fair (Pameran Pendidikan / Edufair)
    if (url.contains('19b4qmykCm_-lZtuRo4yAZbmvvKzdA0Ih')) {
      return 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=600&auto=format&fit=crop';
    }

    if (url.contains('drive.google.com')) {
      final RegExp regExp = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        return 'https://lh3.googleusercontent.com/d/$id';
      }
      
      final RegExp regExpUc = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
      final matchUc = regExpUc.firstMatch(url);
      if (matchUc != null && matchUc.groupCount >= 1) {
        final id = matchUc.group(1);
        return 'https://lh3.googleusercontent.com/d/$id';
      }
    }
    return url;
  }

  static String getEventPlaceholder(String? title, String? category) {
    final t = (title ?? '').toLowerCase();
    final c = (category ?? '').toLowerCase();
    
    if (t.contains('music') || t.contains('konser') || t.contains('festival') || c.contains('music') || c.contains('konser')) {
      return 'https://images.unsplash.com/photo-1506157786151-b8491531f063?q=80&w=600&auto=format&fit=crop';
    }
    if (t.contains('tech') || t.contains('developer') || t.contains('coding') || c.contains('tech') || c.contains('technology')) {
      return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=600&auto=format&fit=crop';
    }
    if (t.contains('education') || t.contains('fair') || t.contains('belajar') || t.contains('edukasi') || c.contains('education') || c.contains('edukasi')) {
      return 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=600&auto=format&fit=crop';
    }
    if (t.contains('sport') || t.contains('olahraga') || t.contains('run') || c.contains('sport') || c.contains('olahraga')) {
      return 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=600&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=600&auto=format&fit=crop';
  }
}

