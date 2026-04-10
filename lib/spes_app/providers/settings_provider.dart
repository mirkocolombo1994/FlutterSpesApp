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

  SettingsState({
    required this.themeMode,
    required this.locationCheckInterval,
    required this.playScanBeep,
    required this.requireCartConfirmation,
    required this.showCartWarnings,
    required this.enableDataSaver,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? locationCheckInterval,
    bool? playScanBeep,
    bool? requireCartConfirmation,
    bool? showCartWarnings,
    bool? enableDataSaver,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locationCheckInterval: locationCheckInterval ?? this.locationCheckInterval,
      playScanBeep: playScanBeep ?? this.playScanBeep,
      requireCartConfirmation: requireCartConfirmation ?? this.requireCartConfirmation,
      showCartWarnings: showCartWarnings ?? this.showCartWarnings,
      enableDataSaver: enableDataSaver ?? this.enableDataSaver,
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
    
    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      locationCheckInterval: interval,
      playScanBeep: beep,
      requireCartConfirmation: confirm,
      showCartWarnings: warn,
      enableDataSaver: dataSaver,
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
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
