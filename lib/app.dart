import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/history_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/theme_provider.dart';
import 'repository/history_repository.dart';
import 'repository/playlist_repository.dart';
import 'repository/settings_repository.dart';
import 'repository/song_repository.dart';
import 'screens/splash/splash_screen.dart';
import 'services/audio_handler.dart';
import 'services/file_import_service.dart';
import 'services/music_scanner_service.dart';

/// Root widget: wires repositories -> providers once, then hands off to
/// SplashScreen. [audioHandler] is created once in main() (audio_service
/// requires this) and threaded down into PlayerProvider here.
class ZenovaApp extends StatelessWidget {
  final ZenovaAudioHandler audioHandler;
  const ZenovaApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    final settingsRepository = SettingsRepository();
    final songRepository = SongRepository();
    final playlistRepository = PlaylistRepository();
    final historyRepository = HistoryRepository();
    final scanner = MusicScannerService();
    final importer = FileImportService(scanner);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsRepository)),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(songRepository, scanner, importer, settingsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(audioHandler, songRepository, historyRepository, settingsRepository),
        ),
        ChangeNotifierProvider(create: (_) => PlaylistProvider(playlistRepository, songRepository)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(historyRepository, songRepository)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Zenova',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light(themeProvider.accentColor),
            darkTheme: AppTheme.dark(themeProvider.accentColor, amoled: themeProvider.amoledEnabled),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
