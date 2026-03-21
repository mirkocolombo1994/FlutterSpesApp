import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_strings.dart';

// Notifier per gestire il tema (chiaro/scuro/sistema)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(AppStrings.themeModeLabel),
          SwitchListTile(
            title: const Text('Tema Scuro'),
            secondary: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, color: Colors.indigo),
            value: themeMode == ThemeMode.dark,
            onChanged: (isDark) {
              ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
            },
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
