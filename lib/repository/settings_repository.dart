import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../core/constants/app_constants.dart';
import '../services/hive_service.dart';

/// Thin key-value wrapper. The settings box stores primitives directly (no
/// custom adapter needed) since every value here is a String/int/bool/List.
class SettingsRepository {
  Box get _box => HiveService.settingsBox;

  T? get<T>(String key) => _box.get(key) as T?;
  Future<void> set(String key, dynamic value) => _box.put(key, value);

  String get themeMode => _box.get(AppConstants.keyThemeMode, defaultValue: 'system') as String;
  Future<void> setThemeMode(String mode) => set(AppConstants.keyThemeMode, mode);

  bool get amoledEnabled => _box.get(AppConstants.keyAmoled, defaultValue: false) as bool;
  Future<void> setAmoledEnabled(bool value) => set(AppConstants.keyAmoled, value);

  int get accentColorValue => _box.get(AppConstants.keyAccentColor, defaultValue: 0xFFF2A93B) as int;
  Future<void> setAccentColorValue(int argb) => set(AppConstants.keyAccentColor, argb);

  bool get hasOnboarded => _box.get(AppConstants.keyHasOnboarded, defaultValue: false) as bool;
  Future<void> setHasOnboarded(bool value) => set(AppConstants.keyHasOnboarded, value);

  double get playbackSpeed =>
      (_box.get(AppConstants.keyPlaybackSpeed, defaultValue: 1.0) as num).toDouble();
  Future<void> setPlaybackSpeed(double speed) => set(AppConstants.keyPlaybackSpeed, speed);

  String get repeatMode => _box.get(AppConstants.keyRepeatMode, defaultValue: 'off') as String;
  Future<void> setRepeatMode(String mode) => set(AppConstants.keyRepeatMode, mode);

  bool get shuffleEnabled => _box.get(AppConstants.keyShuffleEnabled, defaultValue: false) as bool;
  Future<void> setShuffleEnabled(bool value) => set(AppConstants.keyShuffleEnabled, value);

  String get sortSongsBy => _box.get(AppConstants.keySortSongsBy, defaultValue: 'title') as String;
  Future<void> setSortSongsBy(String value) => set(AppConstants.keySortSongsBy, value);

  bool get sortSongsAscending =>
      _box.get(AppConstants.keySortSongsAscending, defaultValue: true) as bool;
  Future<void> setSortSongsAscending(bool value) => set(AppConstants.keySortSongsAscending, value);

  List<String> get lastQueueIds =>
      (_box.get(AppConstants.keyLastQueueIds, defaultValue: <String>[]) as List).cast<String>();
  int get lastQueueIndex => _box.get(AppConstants.keyLastQueueIndex, defaultValue: 0) as int;
  int get lastPositionMs => _box.get(AppConstants.keyLastPositionMs, defaultValue: 0) as int;

  Future<void> saveLastSession({
    required List<String> queueIds,
    required int index,
    required int positionMs,
  }) async {
    await _box.putAll({
      AppConstants.keyLastQueueIds: queueIds,
      AppConstants.keyLastQueueIndex: index,
      AppConstants.keyLastPositionMs: positionMs,
    });
  }
}
