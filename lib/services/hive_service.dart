import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

/// Boots Hive and opens every box the app needs. Call [init] once, before
/// `runApp`, from `main.dart`.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    Hive.registerAdapter(SongModelAdapter());
    Hive.registerAdapter(PlaylistModelAdapter());

    await Future.wait([
      Hive.openBox<SongModel>(AppConstants.songsBox),
      Hive.openBox<PlaylistModel>(AppConstants.playlistsBox),
      Hive.openBox<int>(AppConstants.historyBox),
      Hive.openBox(AppConstants.settingsBox),
    ]);

    _initialized = true;
  }

  static Box<SongModel> get songsBox => Hive.box<SongModel>(AppConstants.songsBox);
  static Box<PlaylistModel> get playlistsBox => Hive.box<PlaylistModel>(AppConstants.playlistsBox);
  static Box<int> get historyBox => Hive.box<int>(AppConstants.historyBox);
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);
}
