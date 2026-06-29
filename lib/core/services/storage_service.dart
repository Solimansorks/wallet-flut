import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> initDefaults() async {
    if (_prefs.getString(_keyLanguage) == null) {
      await setLanguageCode('ar');
    }
  }

  static const String _keyPinHash = 'pin_hash';
  static const String _keyInitialBalance = 'initial_balance';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language_code';
  static const String _keyAutoLogin = 'auto_login';
  static const String _keyLastCategory = 'last_category';

  // Check if initial setup is complete (has PIN)
  bool isPinSet() {
    return _prefs.getString(_keyPinHash) != null;
  }

  // Hash PIN code using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> setPin(String pin) async {
    final hash = _hashPin(pin);
    return await _prefs.setString(_keyPinHash, hash);
  }

  bool verifyPin(String enteredPin) {
    final savedHash = _prefs.getString(_keyPinHash);
    if (savedHash == null) return false;
    return savedHash == _hashPin(enteredPin);
  }

  // Initial Balance Setup
  double getInitialBalance() {
    return _prefs.getDouble(_keyInitialBalance) ?? 0.0;
  }

  Future<bool> setInitialBalance(double balance) async {
    return await _prefs.setDouble(_keyInitialBalance, balance);
  }

  // Auto Login (Skip PIN prompt next time if selected)
  bool isAutoLoginEnabled() {
    return _prefs.getBool(_keyAutoLogin) ?? false;
  }

  Future<bool> setAutoLoginEnabled(bool enabled) async {
    return await _prefs.setBool(_keyAutoLogin, enabled);
  }

  // Hide Balances Preference
  static const String _keyHideBalances = 'hide_balances';

  bool isHideBalancesEnabled() {
    return _prefs.getBool(_keyHideBalances) ?? false;
  }

  Future<bool> setHideBalancesEnabled(bool enabled) async {
    return await _prefs.setBool(_keyHideBalances, enabled);
  }

  // Theme Preference
  bool isDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<bool> setDarkMode(bool enabled) async {
    return await _prefs.setBool(_keyDarkMode, enabled);
  }

  // Language Preference
  String getLanguageCode() {
    return _prefs.getString(_keyLanguage) ?? 'ar'; // Default is Arabic (ar)
  }

  Future<bool> setLanguageCode(String code) async {
    return await _prefs.setString(_keyLanguage, code);
  }

  // Remember Last Category
  String? getLastUsedCategory() {
    return _prefs.getString(_keyLastCategory);
  }

  Future<bool> setLastUsedCategory(String category) async {
    return await _prefs.setString(_keyLastCategory, category);
  }

  // Reset/Clear Data
  Future<bool> clearAll() async {
    final lang = getLanguageCode();
    final theme = isDarkMode();
    
    final success = await _prefs.clear();
    
    // Reset to defaults
    await setLanguageCode(lang);
    await setDarkMode(theme);
    await setInitialBalance(0.0);
    
    return success;
  }
}
