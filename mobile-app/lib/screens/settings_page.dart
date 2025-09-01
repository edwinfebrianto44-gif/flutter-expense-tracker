import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../generated/l10n.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final languageState = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(l10n.theme, context),
          const SizedBox(height: 8),
          _buildThemeModeCard(context, ref, themeState, l10n),
          const SizedBox(height: 8),
          _buildThemeColorCard(context, ref, themeState, l10n),
          
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.language, context),
          const SizedBox(height: 8),
          _buildLanguageCard(context, ref, languageState, l10n),
          
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.notifications, context),
          const SizedBox(height: 8),
          _buildNotificationCard(context, l10n),
          
          const SizedBox(height: 24),
          _buildAboutCard(context, l10n),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeModeCard(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.brightness_6,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.themeSettings),
            subtitle: Text(_getThemeModeText(themeState.themeMode, l10n)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: AppThemeMode.values.map((mode) {
                return RadioListTile<AppThemeMode>(
                  title: Text(_getThemeModeText(mode, l10n)),
                  value: mode,
                  groupValue: themeState.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).setThemeMode(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeColorCard(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.themeColor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AppThemeColor.values.map((color) {
                final isSelected = themeState.themeColor == color;
                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeColor(color);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColorFromThemeColor(color),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _getThemeColorText(themeState.themeColor, l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    WidgetRef ref,
    LanguageState languageState,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.languageSettings),
            subtitle: Text(_getLanguageText(languageState.language, l10n)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: AppLanguage.values.map((language) {
                return RadioListTile<AppLanguage>(
                  title: Text(_getLanguageText(language, l10n)),
                  value: language,
                  groupValue: languageState.language,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(languageProvider.notifier).setLanguage(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.notifications_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.notificationSettings),
        subtitle: const Text('Manage your notification preferences'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.pushNamed('notification-settings');
        },
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('About'),
            subtitle: Text(l10n.appTitle),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version: 1.0.0'),
                SizedBox(height: 4),
                Text('A comprehensive expense tracking application built with Flutter.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.lightMode;
      case AppThemeMode.dark:
        return l10n.darkMode;
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  String _getThemeColorText(AppThemeColor color, AppLocalizations l10n) {
    switch (color) {
      case AppThemeColor.blue:
        return l10n.blue;
      case AppThemeColor.green:
        return l10n.green;
      case AppThemeColor.purple:
        return l10n.purple;
      case AppThemeColor.orange:
        return l10n.orange;
      case AppThemeColor.red:
        return l10n.red;
    }
  }

  String _getLanguageText(AppLanguage language, AppLocalizations l10n) {
    switch (language) {
      case AppLanguage.english:
        return l10n.english;
      case AppLanguage.indonesian:
        return l10n.indonesian;
    }
  }

  Color _getColorFromThemeColor(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.blue:
        return Colors.blue;
      case AppThemeColor.green:
        return Colors.green;
      case AppThemeColor.purple:
        return Colors.purple;
      case AppThemeColor.orange:
        return Colors.orange;
      case AppThemeColor.red:
        return Colors.red;
    }
  }
}
