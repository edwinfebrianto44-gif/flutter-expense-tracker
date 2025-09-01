import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode enumeration
enum AppThemeMode { light, dark, system }

// Theme color enumeration
enum AppThemeColor { blue, green, purple, orange, red }

// Theme state model
class AppThemeState {
  final AppThemeMode themeMode;
  final AppThemeColor themeColor;

  const AppThemeState({
    required this.themeMode,
    required this.themeColor,
  });

  AppThemeState copyWith({
    AppThemeMode? themeMode,
    AppThemeColor? themeColor,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
    );
  }

  // Get primary color based on selected theme color
  Color get primaryColor {
    switch (themeColor) {
      case AppThemeColor.blue:
        return Colors.blue;
      case AppThemeColor.green:
        return Colors.green;
      case AppThemeColor.purple:
        return Colors.purple;
      case AppThemeColor.orange:
        return Colors.orange;
      case AppThemeColor.red:
        return Colors.red;
    }
  }

  // Get color scheme for light theme
  ColorScheme get lightColorScheme {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );
  }

  // Get color scheme for dark theme
  ColorScheme get darkColorScheme {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
  }
}

// Enhanced theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeState> {
  ThemeNotifier() : super(const AppThemeState(
    themeMode: AppThemeMode.light,
    themeColor: AppThemeColor.blue,
  )) {
    _loadTheme();
  }

  static const String _themeModeKey = 'themeMode';
  static const String _themeColorKey = 'themeColor';

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final themeColorIndex = prefs.getInt(_themeColorKey) ?? 0;
    
    state = AppThemeState(
      themeMode: AppThemeMode.values[themeModeIndex],
      themeColor: AppThemeColor.values[themeColorIndex],
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    state = state.copyWith(themeColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.index);
  }

  void toggleTheme() async {
    final newMode = state.themeMode == AppThemeMode.light 
        ? AppThemeMode.dark 
        : AppThemeMode.light;
    await setThemeMode(newMode);
  }

  // Get theme mode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

// Helper provider for checking if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.themeMode == AppThemeMode.dark;
});
