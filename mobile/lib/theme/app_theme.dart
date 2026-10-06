import 'package:flutter/material.dart';

/// Tema aplikasi Kost Akbar — nuansa hangat krem & terakota
/// mengikuti desain antarmuka pada dokumen rancangan.
abstract class AppColors {
  const AppColors._();

  /// Latar krem lembut (#FAF3EC).
  static const Color background = Color(0xFFFAF3EC);

  /// Terakota — warna aksen utama tombol & elemen aktif (#B5451B).
  static const Color terracotta = Color(0xFFB5451B);

  /// Maroon gelap — judul & elemen kuat (#8B3A2A).
  static const Color maroon = Color(0xFF8B3A2A);

  /// Teks utama cokelat arang (#2B211C).
  static const Color textDark = Color(0xFF2B211C);

  /// Teks sekunder (#7A6A5F).
  static const Color textMuted = Color(0xFF7A6A5F);

  /// Kartu putih.
  static const Color card = Colors.white;

  /// Isian form krem (#F5EDE7).
  static const Color field = Color(0xFFF5EDE7);

  /// Teal — status positif / lunas / tersedia.
  static const Color teal = Color(0xFF0F766E);

  /// Amber — status menunggu.
  static const Color amber = Color(0xFFB45309);

  /// Merah lembut — status negatif / keluar.
  static const Color danger = Color(0xFFB3261E);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.terracotta,
          primary: AppColors.terracotta,
          secondary: AppColors.maroon,
          surface: AppColors.card,
          error: AppColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.field,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.terracotta, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.terracotta,
            side: const BorderSide(color: AppColors.terracotta),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.field,
          labelStyle: const TextStyle(color: AppColors.textDark, fontSize: 12),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.field,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.terracotta
                  : AppColors.textMuted,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFEFE3D5)),
      );
}
