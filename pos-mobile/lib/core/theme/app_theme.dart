import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette (matches web app CSS variables) ──────────────────
  static const Color primary      = Color(0xFFFA7BC2); // --primary
  static const Color primaryDark  = Color(0xFFD65BA1); // --primary-dark
  static const Color primaryLight = Color(0xFFFDE8F3); // --primary-light
  static const Color accent       = Color(0xFF06B6D4); // --accent (cyan)
  static const Color success      = Color(0xFF10B981); // --success
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning      = Color(0xFFF59E0B); // --warning
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color danger       = Color(0xFFEF4444); // --danger
  static const Color dangerLight  = Color(0xFFFEF2F2);

  // Sidebar (matches web --sidebar-bg)
  static const Color sidebarBg     = Color(0xFF0F172A);
  static const Color sidebarText   = Color(0xFF64748B);
  static const Color sidebarTextH  = Color(0xFF94A3B8);
  static const Color sidebarActive = Color(0xFFC7D2FE);

  // Body & Cards
  static const Color bodyBg      = Color(0xFFF1F5F9); // --body-bg
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B); // --text-primary
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted   = Color(0xFF94A3B8);
  static const Color border      = Color(0xFFE2E8F0);

  // ── Chart Colors ────────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFFFA7BC2),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  // ── Shadows ─────────────────────────────────────────────────────────
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    offset: Offset(0, 4),
    spreadRadius: -1,
  );

  // ── Border Radius ───────────────────────────────────────────────────
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radius   = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));

  // ── MaterialApp ThemeData ───────────────────────────────────────────
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        error: danger,
        surface: cardBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: bodyBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        bodyMedium: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        bodySmall: GoogleFonts.inter(color: textSecondary, fontSize: 12),
        titleLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelLarge: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: border,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: danger),
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bodyBg,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        side: const BorderSide(color: border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: const RoundedRectangleBorder(borderRadius: radiusSm),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
