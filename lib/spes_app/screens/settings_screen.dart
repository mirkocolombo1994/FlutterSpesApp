import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_strings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(AppStrings.themeModeLabel),
          SwitchListTile(
            title: const Text('Tema Scuro'),
            secondary: Icon(settings.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, color: Colors.indigo),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (isDark) {
              ref.read(settingsProvider.notifier).setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.locationSettingsSection),
          ListTile(
            leading: const Icon(Icons.location_searching, color: Colors.indigo),
            title: const Text(AppStrings.locationIntervalLabel),
            subtitle: Text('${settings.locationCheckInterval} ${AppStrings.minutesLabel}'),
            trailing: DropdownButton<int>(
              value: settings.locationCheckInterval,
              items: [1, 2, 5, 10, 15].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value ${AppStrings.minutesLabel}'),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  ref.read(settingsProvider.notifier).setLocationCheckInterval(newValue);
                }
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader('Scanner e Carrello'),
          SwitchListTile(
            title: const Text('Suono/Vibrazione Scanner'),
            subtitle: const Text('Feedback al riconoscimento del codice'),
            secondary: const Icon(Icons.vibration, color: Colors.indigo),
            value: settings.playScanBeep,
            onChanged: (val) => ref.read(settingsProvider.notifier).setPlayScanBeep(val),
          ),
          SwitchListTile(
            title: const Text('Conferma Aggiunta Carrello'),
            subtitle: const Text('Chiedi la quantità prima di aggiungere prodotti noti'),
            secondary: const Icon(Icons.exposure_plus_1, color: Colors.indigo),
            value: settings.requireCartConfirmation,
            onChanged: (val) => ref.read(settingsProvider.notifier).setRequireCartConfirmation(val),
          ),
          SwitchListTile(
            title: const Text('Avvisi Prezzi nel Carrello'),
            subtitle: const Text('Mostra alert se mancano prezzi o negozi'),
            secondary: const Icon(Icons.warning_amber_rounded, color: Colors.indigo),
            value: settings.showCartWarnings,
            onChanged: (val) => ref.read(settingsProvider.notifier).setShowCartWarnings(val),
          ),
          const Divider(),
          _buildSectionHeader('Cloud e Dati'),
          SwitchListTile(
            title: const Text('Risparmio Dati (Open Food Facts)'),
            subtitle: const Text('Ignora il download delle immagini HD dei prodotti'),
            secondary: const Icon(Icons.data_saver_on, color: Colors.indigo),
            value: settings.enableDataSaver,
            onChanged: (val) => ref.read(settingsProvider.notifier).setEnableDataSaver(val),
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.aboutAppLabel),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData 
                  ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}' 
                  : AppStrings.loading;
              return ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.indigo),
                title: const Text(AppStrings.appVersionPrefix),
                subtitle: Text(version),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              AppStrings.aboutAppDescription,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
