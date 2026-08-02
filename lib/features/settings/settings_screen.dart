import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/notification_scheduler.dart';
import '../../data/platform/external_services.dart';
import '../../data/platform/platform_capabilities.dart';
import '../../data/settings/settings_service.dart';
import '../../data/sync/sync_service.dart';
import '../account/account_screen.dart';
import 'about_screen.dart';

/// Settings page (spec §4.5): playback defaults, downloads, notifications,
/// account, about. All settings are local per device; section visibility is
/// gated by [PlatformCapabilities] flags, never raw platform checks.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final service = ref.read(settingsServiceProvider);
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final signedIn = ref.watch(signedInEmailProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Playback'),
          _DropdownTile(
            title: 'Streaming quality',
            value: settings.streamQuality,
            options: const {
              'auto': 'Auto (best available)',
              '1080': '1080p',
              '720': '720p',
              '480': '480p',
            },
            onChanged: service.setStreamQuality,
          ),
          _DropdownTile(
            title: 'Streaming variant',
            value: settings.streamVariant,
            options: const {'ensub': 'English subtitles', 'dub': 'English dub'},
            onChanged: service.setStreamVariant,
          ),
          _DropdownTile(
            title: 'Subtitles (downloaded episodes)',
            value: settings.subtitleLang,
            options: const {'eng': 'English', 'jpn': 'Japanese', 'off': 'Off'},
            onChanged: service.setSubtitleLang,
          ),
          _DropdownTile(
            title: 'Audio (downloaded episodes)',
            value: settings.audioLang,
            options: const {'jpn': 'Japanese', 'eng': 'English'},
            onChanged: service.setAudioLang,
          ),
          SwitchListTile(
            title: const Text('Autoplay next episode'),
            subtitle: const Text(
                'Start the next episode after a 5-second countdown'),
            value: settings.autoplayNext,
            onChanged: service.setAutoplayNext,
          ),
          const Divider(),
          const _SectionHeader('Downloads'),
          if (capabilities.canChooseDownloadDir)
            ListTile(
              title: const Text('Download folder'),
              subtitle: Text(settings.downloadDir.isEmpty
                  ? 'App-managed folder'
                  : settings.downloadDir),
              trailing: settings.downloadDir.isEmpty
                  ? const Icon(Icons.folder_open)
                  : IconButton(
                      icon: const Icon(Icons.restart_alt),
                      tooltip: 'Use the app-managed folder',
                      onPressed: () => service.setDownloadDir(''),
                    ),
              onTap: () async {
                final dir = await pickFolder(
                    initialDirectory: settings.downloadDir.isEmpty
                        ? null
                        : settings.downloadDir);
                if (dir != null) await service.setDownloadDir(dir);
              },
            ),
          if (capabilities.hasCellularToggle)
            SwitchListTile(
              title: const Text('Wi-Fi only'),
              subtitle: const Text('Never download over cellular data'),
              value: settings.wifiOnly,
              onChanged: service.setWifiOnly,
            ),
          SwitchListTile(
            title: const Text('Auto-delete watched episodes'),
            subtitle:
                const Text('Remove a download once you finish the episode'),
            value: settings.autoDeleteWatched,
            onChanged: service.setAutoDeleteWatched,
          ),
          const Divider(),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Notify me about new episodes'),
            subtitle: Text(switch (capabilities.notificationStyle) {
              NotificationStyle.androidLocal =>
                'Checks daily in the background and shows a notification.',
              NotificationStyle.iosBestEffort =>
                'Best effort — iOS decides when sideloaded apps may check '
                    'in the background. The in-app bell always catches up.',
              NotificationStyle.desktopToast =>
                'Shows a system notification when the running app finds '
                    'new episodes.',
            }),
            value: settings.notifyNewEpisodes,
            onChanged: (value) async {
              // The scheduler owns the permission request (in context, per
              // spec §9.4) and the background-poll registration.
              final granted = await ref
                  .read(notificationSchedulerProvider)
                  .setEnabled(value);
              if (!granted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Notification permission was denied — '
                      'the in-app bell still shows new releases.'),
                ));
              }
            },
          ),
          const Divider(),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(signedIn ?? 'Sign in to sync watch progress'),
            subtitle: signedIn == null
                ? null
                : const Text('Signed in — watch progress syncs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AccountScreen(),
            )),
          ),
          const Divider(),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About grand-line'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AboutScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: options.containsKey(value) ? value : options.keys.first,
        underline: const SizedBox.shrink(),
        items: [
          for (final entry in options.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
