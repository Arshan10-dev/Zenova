import 'package:flutter/animation.dart';

/// Central place for magic numbers/strings so services, repositories, and
/// providers don't drift out of sync with each other.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cadence';

  // --- Hive box names ---
  static const String songsBox = 'songs_box';
  static const String playlistsBox = 'playlists_box';
  static const String historyBox = 'history_box'; // songId -> lastPlayedAt (int)
  static const String settingsBox = 'settings_box';

  // --- Settings keys (settingsBox) ---
  static const String keyThemeMode = 'theme_mode';
  static const String keyAmoled = 'amoled_enabled';
  static const String keyAccentColor = 'accent_color';
  static const String keyHasOnboarded = 'has_onboarded';
  static const String keyLastQueueIds = 'last_queue_ids';
  static const String keyLastQueueIndex = 'last_queue_index';
  static const String keyLastPositionMs = 'last_position_ms';
  static const String keyShuffleEnabled = 'shuffle_enabled';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keyPlaybackSpeed = 'playback_speed';
  static const String keySortSongsBy = 'sort_songs_by';
  static const String keySortSongsAscending = 'sort_songs_ascending';

  static const List<String> supportedExtensions = ['mp3', 'm4a', 'flac', 'wav', 'aac', 'ogg'];

  static const int maxHistoryEntries = 300;
  static const int homeSectionItemLimit = 12;

  static const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const List<Duration> sleepTimerOptions = [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];

  static const Duration animFast = Duration(milliseconds: 160);
  static const Duration animMedium = Duration(milliseconds: 280);
  static const Duration animSlow = Duration(milliseconds: 420);
  static const Curve animCurve = Curves.easeOutCubic;

  static const double miniPlayerHeight = 64;
  static const double bottomNavHeight = 64;
}
