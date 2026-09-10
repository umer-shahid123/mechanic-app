import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light Mode (White & Green)
  static const Color primary = Color(0xFF22C55E); 
  static const Color secondary = Color(0xFF166534); 
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF064E3B);
  static const Color grey = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color success = Color(0xFF16A34A); 
  static const Color error = Color(0xFFDC2626);
  static const Color sosRed = Color(0xFFFF3B30);

  // Level Colors
  static const Color levelBronze = Color(0xFFCD7F32);
  static const Color levelSilver = Color(0xFFC0C0C0);
  static const Color levelGold = Color(0xFFFFD700);
  static const Color levelDiamond = Color(0xFFB9F2FF);

  // Stealth Dark Mode (Deep Charcoal & Neon Green)
  static const Color darkBg = Color(0xFF0A0C10);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color neonGreen = Color(0xFF26FF75);
  static const Color darkText = Colors.white;
  static const Color darkGrey = Color(0xFF8B949E);

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get darkGradient => const LinearGradient(
    colors: [Color(0xFF166534), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: neonGreen.withValues(alpha: 0.2),
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];
}

class AppTheme {
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textDark,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.divider,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
        displayMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        bodyLarge: const TextStyle(fontSize: 14, color: AppColors.textDark),
        bodyMedium: const TextStyle(fontSize: 12, color: AppColors.textDark),
        labelLarge: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.neonGreen,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      dividerColor: Colors.white10,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
        displayMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: const TextStyle(fontSize: 14, color: Colors.white),
        bodyMedium: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
        labelLarge: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.neonGreen),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.darkGrey,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
