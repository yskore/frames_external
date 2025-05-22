import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/notification_settings_model.dart';
import 'package:frames_app/providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  final String username;

  const NotificationSettingsScreen({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (settings == null) {
            return const Center(child: Text('No settings found'));
          }
          return _buildSettingsList(context, ref, settings);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading settings: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(notificationSettingsProvider.notifier)
                      .loadSettings(username),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(
      BuildContext context, WidgetRef ref, NotificationSettings settings) {
    final settingsMap = {
      'user_posted_piece': 'When users post a new piece',
      'user_made_piece_live': 'When users make a piece available',
      'user_listed_piece_for_sale': 'When users list a piece for sale',
      'user_made_offer': 'When users make an offer',
      'user_liked_piece': 'When users like your pieces',
      'user_subscribed': 'When users subscribe to you',
    };

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Customize which notifications you want to receive',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...settingsMap.entries.map((entry) {
          final key = entry.key;
          final description = entry.value;
          final isEnabled = settings.settings[key] ?? true;

          return SwitchListTile(
            title: Text(description),
            value: isEnabled,
            onChanged: (value) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting(key);
            },
          );
        }),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'You\'ll always receive important notifications about your offers and pieces.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      ],
    );
  }
}
