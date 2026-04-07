import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final int locationCheckInterval; // in minutes

  SettingsState({
    required this.themeMode,
    required this.locationCheckInterval,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? locationCheckInterval,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locationCheckInterval: locationCheckInterval ?? this.locationCheckInterval,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _themeKey = 'theme_mode';
  static const String _intervalKey = 'location_interval';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(
      themeMode: ThemeMode.light,
      locationCheckInterval: 5,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    final interval = prefs.getInt(_intervalKey) ?? 5;
    
    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      locationCheckInterval: interval,
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
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
