import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool hideBalances;

  SettingsState({
    required this.themeMode,
    required this.locale,
    required this.hideBalances,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? hideBalances,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      hideBalances: hideBalances ?? this.hideBalances,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsController(this._ref)
      : super(SettingsState(
          themeMode: ThemeMode.system,
          locale: const Locale('ar'),
          hideBalances: false,
        )) {
    _loadSettings();
  }

  void _loadSettings() {
    final storage = _ref.read(storageServiceProvider);
    
    // Load theme
    final isDark = storage.isDarkMode();
    final theme = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load locale
    final lang = storage.getLanguageCode();
    final locale = Locale(lang);

    // Load hide balance
    final hideBalances = storage.isHideBalancesEnabled();

    state = SettingsState(themeMode: theme, locale: locale, hideBalances: hideBalances);
  }

  Future<void> toggleTheme(bool isDark) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setDarkMode(isDark);
    state = state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleLanguage() async {
    final storage = _ref.read(storageServiceProvider);
    final currentLang = state.locale.languageCode;
    final newLang = currentLang == 'ar' ? 'en' : 'ar';
    
    await storage.setLanguageCode(newLang);
    final newLocale = Locale(newLang);
    
    state = state.copyWith(locale: newLocale);
  }

  Future<void> toggleHideBalances(bool val) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setHideBalancesEnabled(val);
    state = state.copyWith(hideBalances: val);
  }

  Future<void> resetAllSettings() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.clearAll();
    _loadSettings();
  }
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref);
});
