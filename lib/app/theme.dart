import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppTheme {
  // Brand Colors (Soft Playful & Warm Family)
  static const primary = Color(0xFF5B5FEF);
  static const primaryLight = Color(0xFFEEF0FF);
  static const secondary = Color(0xFFFF8A3D);
  static const success = Color(0xFF00C48C);
  static const urgent = Color(0xFFFF4B4B);
  static const background = Color(0xFFF8F9FD);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF191F28);
  static const textSecondary = Color(0xFF8B95A1);
  static const border = Color(0xFFF2F4F6);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: surface,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          elevation: 4,
          indicatorColor: primaryLight,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary);
            }
            return const IconThemeData(color: textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: border, width: 1.2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      );

  static Color dDayColor(int d) {
    if (d < 0) return const Color(0xFFFF4B4B); // 지연 (코랄 레드)
    if (d == 0) return const Color(0xFFFF7A00); // 오늘 마감 (선명한 오렌지)
    if (d == 1) return const Color(0xFFFFA800); // 내일 마감 (앰버 골드)
    return const Color(0xFF00B074); // 여유 (민트 에메랄드)
  }

  static Color dDayBgColor(int d) {
    return dDayColor(d).withOpacity(0.12);
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'done': return success;
      case 'in_progress': return primary;
      case 'registered': return secondary;
      default: return textSecondary;
    }
  }

  static Color categoryColor(Category cat) {
    switch (cat) {
      case Category.school: return const Color(0xFF3182F6);
      case Category.english: return const Color(0xFFFF8A3D);
      case Category.math: return const Color(0xFF00C48C);
      case Category.essay: return const Color(0xFF845EF7);
      case Category.etc: return const Color(0xFF495057);
    }
  }
}
