import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final int locationCheckInterval; // in minutes
  final bool playScanBeep;
  final bool requireCartConfirmation;
  final bool showCartWarnings;
  final bool enableDataSaver;
  final bool enableSuperfastMode;
  final String geminiApiKey;

  SettingsState({
    required this.themeMode,
    required this.locationCheckInterval,
    required this.playScanBeep,
    required this.requireCartConfirmation,
    required this.showCartWarnings,
    required this.enableDataSaver,
    required this.enableSuperfastMode,
    required this.geminiApiKey,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? locationCheckInterval,
    bool? playScanBeep,
    bool? requireCartConfirmation,
    bool? showCartWarnings,
    bool? enableDataSaver,
    bool? enableSuperfastMode,
    String? geminiApiKey,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locationCheckInterval: locationCheckInterval ?? this.locationCheckInterval,
      playScanBeep: playScanBeep ?? this.playScanBeep,
      requireCartConfirmation: requireCartConfirmation ?? this.requireCartConfirmation,
      showCartWarnings: showCartWarnings ?? this.showCartWarnings,
      enableDataSaver: enableDataSaver ?? this.enableDataSaver,
      enableSuperfastMode: enableSuperfastMode ?? this.enableSuperfastMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _themeKey = 'theme_mode';
  static const String _intervalKey = 'location_interval';
  static const String _beepKey = 'play_scan_beep';
  static const String _confirmKey = 'require_cart_confirmation';
  static const String _warnKey = 'show_cart_warnings';
  static const String _dataSaverKey = 'enable_data_saver';
  static const String _superfastKey = 'enable_superfast_mode';
  static const String _geminiKey = 'gemini_api_key';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(
      themeMode: ThemeMode.light,
      locationCheckInterval: 5,
      playScanBeep: true,
      requireCartConfirmation: false,
      showCartWarnings: true,
      enableDataSaver: false,
      enableSuperfastMode: false,
      geminiApiKey: '',
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    final interval = prefs.getInt(_intervalKey) ?? 5;
    final beep = prefs.getBool(_beepKey) ?? true;
    final confirm = prefs.getBool(_confirmKey) ?? false;
    final warn = prefs.getBool(_warnKey) ?? true;
    final dataSaver = prefs.getBool(_dataSaverKey) ?? false;
    final superfast = prefs.getBool(_superfastKey) ?? false;
    final geminiKey = prefs.getString(_geminiKey) ?? '';
    
    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      locationCheckInterval: interval,
      playScanBeep: beep,
      requireCartConfirmation: confirm,
      showCartWarnings: warn,
      enableDataSaver: dataSaver,
      enableSuperfastMode: superfast,
      geminiApiKey: geminiKey,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLocationCheckInterval(int minutes) async {
    state = state.copyWith(locationCheckInterval: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalKey, minutes);
  }

  Future<void> setPlayScanBeep(bool value) async {
    state = state.copyWith(playScanBeep: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_beepKey, value);
  }

  Future<void> setRequireCartConfirmation(bool value) async {
    state = state.copyWith(requireCartConfirmation: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_confirmKey, value);
  }

  Future<void> setShowCartWarnings(bool value) async {
    state = state.copyWith(showCartWarnings: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_warnKey, value);
  }

  Future<void> setEnableDataSaver(bool value) async {
    state = state.copyWith(enableDataSaver: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataSaverKey, value);
  }

  Future<void> setEnableSuperfastMode(bool value) async {
    state = state.copyWith(enableSuperfastMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_superfastKey, value);
  }

  Future<void> setGeminiApiKey(String value) async {
    state = state.copyWith(geminiApiKey: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
