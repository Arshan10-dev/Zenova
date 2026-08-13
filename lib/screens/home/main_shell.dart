import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/Zenova_scaffold.dart';
import '../albums/albums_screen.dart';
import '../artists/artists_screen.dart';
import '../settings/settings_screen.dart';
import '../songs/songs_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _bootstrapped = false;

  static const List<Widget> _screens = [
    HomeScreen(),
    SongsScreen(),
    AlbumsScreen(),
    ArtistsScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note_rounded), label: 'Songs'),
    NavigationDestination(icon: Icon(Icons.album_outlined), selectedIcon: Icon(Icons.album_rounded), label: 'Albums'),
    NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Artists'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final library = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();

    // Permission was already confirmed by Splash/Permission before MainShell
    // is ever reached, so this just needs to run the scan itself.
    await library.scanLibrary(requestPermissionIfNeeded: false);
    if (!mounted) return;
    await player.restoreLastSession(library.allSongs);
  }

  @override
  Widget build(BuildContext context) {
    return ZenovaScaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
