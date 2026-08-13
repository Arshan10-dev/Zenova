import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/library_provider.dart';
import '../../providers/theme_provider.dart';
import '../favorites/favorites_screen.dart';
import '../folders/folders_screen.dart';
import '../playlists/playlists_screen.dart';

const String _appVersion = '1.0.0';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          _SectionLabel('Library'),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Folders'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoldersScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: const Text('Favorites'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: const Text('Playlists'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlaylistsScreen())),
          ),
          const Divider(height: 32),

          _SectionLabel('Appearance'),
          const _ThemeModeTile(),
          const _AmoledTile(),
          const _AccentColorTile(),
          const Divider(height: 32),

          _SectionLabel('Library Management'),
          const _RescanTile(),
          const Divider(height: 32),

          _SectionLabel('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Zenova'),
            onTap: () => _showAboutSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _showPrivacySheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.tag_rounded),
            title: const Text('Version'),
            trailing: Text(_appVersion, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppColors.darkBackground),
                  child: const Icon(Icons.graphic_eq_rounded, color: AppColors.ember, size: 30),
                ),
                const SizedBox(height: 16),
                Text('Zenova', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Version $_appVersion', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Text(
                  'A premium offline music player. Your library, your device, no accounts and no streaming.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Policy', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  'Zenova is an offline music player. Your song library, playlists, favorites, and listening '
                  'history are stored only on this device and are never uploaded or shared.\n\n'
                  'Zenova requests permission to read audio files so it can build your library, and a '
                  'notification permission so playback controls can appear while the app is in the background. '
                  'Neither permission is used to access anything beyond what\'s needed for playback.\n\n'
                  'This screen is a starting template — replace it with your own policy before publishing.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.dark_mode_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 20),
          Expanded(child: Text('Theme', style: theme.textTheme.bodyLarge)),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {themeProvider.themeMode},
            onSelectionChanged: (set) => context.read<ThemeProvider>().setThemeMode(set.first),
          ),
        ],
      ),
    );
  }
}

class _AmoledTile extends StatelessWidget {
  const _AmoledTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return SwitchListTile(
      secondary: const Icon(Icons.contrast_rounded),
      title: const Text('AMOLED Black'),
      subtitle: const Text('Pure black background to save battery on OLED screens'),
      value: themeProvider.amoledEnabled,
      onChanged: (value) => context.read<ThemeProvider>().setAmoledEnabled(value),
    );
  }
}

class _AccentColorTile extends StatelessWidget {
  const _AccentColorTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 20),
              Text('Accent Color', style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: AppColors.accentOptions.map((named) {
              final selected = themeProvider.accentColor.toARGB32() == named.color.toARGB32();
              return GestureDetector(
                onTap: () => context.read<ThemeProvider>().setAccentColor(named.color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: named.color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                        : null,
                  ),
                  child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RescanTile extends StatelessWidget {
  const _RescanTile();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    return ListTile(
      leading: library.isScanning
          ? const Padding(
              padding: EdgeInsets.all(2),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : const Icon(Icons.refresh_rounded),
      title: const Text('Scan Music Again'),
      subtitle: Text('${library.allSongs.length} songs in your library'),
      onTap: library.isScanning ? null : () => context.read<LibraryProvider>().scanLibrary(),
    );
  }
}
