import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/platform/external_services.dart';
import 'support_links.dart';

final _appVersionProvider = FutureProvider<String>((ref) => appVersion());

/// About page (spec §10.4): the "what this is / what this isn't" disclaimer,
/// attribution + donation links, license, and version.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(_appVersionProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.sailing, size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('grand-line',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(version == null ? '' : 'v$version · GPL-3.0',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('What this is',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'A free, ad-free, open-source app for streaming and downloading '
            'One Pace — the fan-made recut of One Piece that trims filler '
            'and pacing to follow the manga. All credit for One Pace itself '
            'goes to the One Pace team; this app just plays the releases '
            'they publish.',
          ),
          const SizedBox(height: 16),
          Text("What this isn't",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Not an official One Pace project, and not affiliated with the '
            'One Pace team, Toei Animation, Shueisha, or Crunchyroll. This '
            'app hosts no video — it plays the streams and torrents the One '
            'Pace project distributes. One Piece is the property of its '
            'rights holders; please support the official releases.',
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Support One Pace'),
            subtitle: const Text(
                'Donations cover their hosting and streaming costs'),
            onTap: () => openExternalUrl(onePaceSupportUrl),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('onepace.net'),
            onTap: () => openExternalUrl(onePaceSiteUrl),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source code'),
            subtitle: const Text(projectRepoUrl),
            onTap: () => openExternalUrl(projectRepoUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open-source licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'grand-line',
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}
