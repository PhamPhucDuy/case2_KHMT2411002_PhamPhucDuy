// TASKMANAGER_UI_V1
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const Color _brand = Color(0xFF4563DB);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: brightness,
    );
    final surface = dark ? const Color(0xFF1C2638) : Colors.white;
    final border = dark
        ? const Color(0xFF354258)
        : const Color(0xFFE2E8F2);
    final background = dark
        ? const Color(0xFF111827)
        : const Color(0xFFF5F7FC);

    OutlineInputBorder fieldBorder(Color stroke, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: stroke, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: fieldBorder(border),
        enabledBorder: fieldBorder(border),
        focusedBorder: fieldBorder(scheme.primary, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();
  static const _storageKey = 'task_manager_dark_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = (prefs.getBool(_storageKey) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (_) {
      _mode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, isDark);
    } catch (_) {
      // Neu luu that bai, giao dien van doi mau trong phien nay.
    }
  }
}