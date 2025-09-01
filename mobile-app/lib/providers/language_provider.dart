import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Supported languages
enum AppLanguage { english, indonesian }

// Language state model
class LanguageState {
  final AppLanguage language;
  final Locale locale;

  const LanguageState({
    required this.language,
    required this.locale,
  });

  LanguageState copyWith({
    AppLanguage? language,
    Locale? locale,
  }) {
    return LanguageState(
      language: language ?? this.language,
      locale: locale ?? this.locale,
    );
  }

  static const defaultState = LanguageState(
    language: AppLanguage.indonesian,
    locale: Locale('id', 'ID'),
  );
}

// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(LanguageState.defaultState) {
    _loadLanguage();
  }

  static const String _languageKey = 'selectedLanguage';

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageIndex = prefs.getInt(_languageKey) ?? 1; // Default to Indonesian
    
    final language = AppLanguage.values[languageIndex];
    final locale = _getLocaleFromLanguage(language);
    
    state = LanguageState(
      language: language,
      locale: locale,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    final locale = _getLocaleFromLanguage(language);
    
    state = LanguageState(
      language: language,
      locale: locale,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, language.index);
  }

  Locale _getLocaleFromLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return const Locale('en', 'US');
      case AppLanguage.indonesian:
        return const Locale('id', 'ID');
    }
  }

  String getLanguageName(AppLanguage language, bool isInCurrentLanguage) {
    if (isInCurrentLanguage) {
      // Return language name in the current selected language
      switch (state.language) {
        case AppLanguage.english:
          return language == AppLanguage.english ? 'English' : 'Indonesian';
        case AppLanguage.indonesian:
          return language == AppLanguage.english ? 'Bahasa Inggris' : 'Bahasa Indonesia';
      }
    } else {
      // Return language name in its own language
      switch (language) {
        case AppLanguage.english:
          return 'English';
        case AppLanguage.indonesian:
          return 'Bahasa Indonesia';
      }
    }
  }

  void toggleLanguage() async {
    final newLanguage = state.language == AppLanguage.english 
        ? AppLanguage.indonesian 
        : AppLanguage.english;
    await setLanguage(newLanguage);
  }
}

// Helper provider for getting current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).locale;
});
