import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/settings_service.dart';
import 'package:my_app/core/providers/settings_provider.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  final _settingsProvider = SettingsProvider();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsProvider,
      builder: (context, _) {
        final currentTheme = _settingsProvider.themeMode == ThemeMode.light 
            ? 'light' 
            : _settingsProvider.themeMode == ThemeMode.dark ? 'dark' : 'system';
            
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('App Preferences', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme
              _buildSettingCard(
                context,
                icon: Icons.palette_outlined,
                title: 'Theme',
                child: Column(
                  children: [
                    ...['light', 'dark', 'system'].map((theme) {
                      return RadioListTile<String>(
                        title: Text(theme == 'light' ? 'Light' : theme == 'dark' ? 'Dark' : 'System'),
                        value: theme,
                        groupValue: currentTheme,
                        onChanged: (value) => _settingsProvider.updateTheme(value!),
                        activeColor: AppColors.primary,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Language
              _buildSettingCard(
                context,
                icon: Icons.language_rounded,
                title: 'Language',
                child: Column(
                  children: [
                    ...['en', 'hi', 'mr'].map((lang) {
                      final langName = lang == 'en' ? 'English' : lang == 'hi' ? 'हिंदी' : 'मराठी';
                      return RadioListTile<String>(
                        title: Text(langName),
                        value: lang,
                        groupValue: _settingsProvider.language,
                        onChanged: (value) => _settingsProvider.updateLanguage(value!),
                        activeColor: AppColors.primary,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Currency
              _buildSettingCard(
                context,
                icon: Icons.currency_rupee_rounded,
                title: 'Currency Symbol',
                child: Column(
                  children: [
                    ...['₹', '\$', '€'].map((curr) {
                      return RadioListTile<String>(
                        title: Text(curr),
                        value: curr,
                        groupValue: _settingsProvider.currency,
                        onChanged: (value) => _settingsProvider.updateCurrency(value!),
                        activeColor: AppColors.primary,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingCard(BuildContext context, {required IconData icon, required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
