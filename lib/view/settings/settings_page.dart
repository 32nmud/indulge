import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/theme_provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/settings/activity_type_list_page.dart';

import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/services/backup_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader('Appearance'),
                _buildThemeSwitchTile(context),
                const Divider(),
                _buildSectionHeader('Activity Configuration'),
                _buildListTile(
                  context,
                  icon: Icons.category,
                  title: 'Manage Categories',
                  subtitle: 'Add, edit, or remove activity categories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const ActivityTypeListPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildSectionHeader('Data Management'),
                _buildListTile(
                  context,
                  icon: Icons.download,
                  title: 'Export Data',
                  subtitle: 'Export all data to a JSON file',
                  onTap: () => _exportData(context),
                ),
                _buildListTile(
                  context,
                  icon: Icons.upload,
                  title: 'Import Data',
                  subtitle: 'Import data from a JSON file',
                  onTap: () => _importData(context),
                ),
                _buildListTile(
                  context,
                  icon: Icons.refresh,
                  title: 'Reset Database',
                  subtitle: 'Delete all data and restore to initial state',
                  onTap: () => _confirmResetDatabase(context),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
                const Divider(),
                _buildSectionHeader('About'),
                _buildListTile(
                  context,
                  icon: Icons.info,
                  title: 'Version',
                  subtitle: 'Beta 0.0.3',
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeSwitchTile(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Use light theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Use dark theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system theme settings'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final repo = await SexualEventRepository.create();
      final backupService = BackupService(repo);

      await backupService.exportData();

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final streamController = StreamController<String>();

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Importing Data'),
        content: StreamBuilder<String>(
          stream: streamController.stream,
          initialData: 'Initializing import...',
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(snapshot.data ?? 'Processing...'),
              ],
            );
          },
        ),
      ),
    );

    try {
      final repo = await SexualEventRepository.create();
      final backupService = BackupService(repo);

      await for (final update in backupService.importData()) {
        streamController.add(update);
      }

      // Refresh the provider data
      if (context.mounted) {
        streamController.add('Refreshing app data...');
        await context.read<SexualEventsProvider>().refreshAllData();
      }

      streamController.add('Import complete!');

      // Allow user to see "Complete" message briefly
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      streamController.add('Error: $e');
      // Keep dialog open for a bit so user sees error
      await Future.delayed(const Duration(seconds: 3));
    } finally {
      await streamController.close();
      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _confirmResetDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text(
          'This will permanently delete all your data including events, '
          'contacts, and custom activities. This action cannot be undone.\n\n'
          'The database will be restored to its initial state with default '
          'categories and the anonymous contact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _resetDatabase(context);
    }
  }

  Future<void> _resetDatabase(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Resetting database...'),
            ],
          ),
        ),
      );

      // Delete the database file
      final dbPath = join(await getDatabasesPath(), 'indulge.db');
      await deleteDatabase(dbPath);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show success dialog with restart instructions
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Database Reset Complete'),
            content: const Text(
              'The database has been reset successfully.\n\n'
              'Please close and restart the app to complete the process.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
