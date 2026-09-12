import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LanguageService manages the app's current display language.
///
/// This is a simple, custom approach (not the full flutter_localizations
/// framework) — deliberately kept lightweight given the hackathon
/// timeline. It stores the selected language code in SharedPreferences
/// (so it persists across app restarts) and notifies listeners so the
/// UI rebuilds when the language changes.
///
/// Supported languages match the ones already used in Add Patient's
/// "preferred language" dropdown: English, Assamese, Bengali, Manipuri,
/// Hindi.
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language_code';

  // Language codes used as keys into AppStrings' translation map.
  static const String english = 'en';
  static const String assamese = 'as';
  static const String bengali = 'bn';
  static const String manipuri = 'mni';
  static const String hindi = 'hi';

  static const Map<String, String> displayNames = {
    english: 'English',
    assamese: 'Assamese (অসমীয়া)',
    bengali: 'Bengali (বাংলা)',
    manipuri: 'Manipuri (মৈতৈলোন্)',
    hindi: 'Hindi (हिन्दी)',
  };

  String _currentLanguage = english;
  String get currentLanguage => _currentLanguage;

  /// Call this once at app startup (e.g. in main()) to load the
  /// previously saved language before the first frame renders.
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_languageKey);
      if (saved != null && displayNames.containsKey(saved)) {
        _currentLanguage = saved;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved language: $e');
      // Falls back to English — never block app startup on this.
    }
  }

  /// Change the app's language and persist the choice.
  Future<void> setLanguage(String languageCode) async {
    if (!displayNames.containsKey(languageCode)) return;
    _currentLanguage = languageCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error saving language preference: $e');
      // Non-fatal — the in-memory change still applies for this session.
    }
  }
}

/// A single global instance, referenced app-wide. Simpler than threading
/// a provider through every screen given the timeline — every screen
/// that needs translated text just imports this file and reads
/// `languageService.currentLanguage`, and wraps itself in a
/// ListenableBuilder (see AppStrings usage examples) to rebuild when it
/// changes.
final LanguageService languageService = LanguageService();
