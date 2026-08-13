import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../models/song_model.dart';
import '../repository/history_repository.dart';
import '../repository/settings_repository.dart';
import '../repository/song_repository.dart';
import '../services/audio_handler.dart';

class PlayerProvider extends ChangeNotifier {
  final CadenceAudioHandler audioHandler;
  final SongRepository _songRepository;
  final HistoryRepository _historyRepository;
  final SettingsRepository _settings;

  PlayerProvider(this.audioHandler, this._songRepository, this._historyRepository, this._settings) {
    _bootstrap();
  }

  String? _lastRecordedSongId;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;
  Timer? _sessionPersistTimer;
  bool _shuffleEnabled = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  double _speed = 1.0;
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _playbackStateSub;

  Stream<MediaItem?> get mediaItemStream => audioHandler.mediaItem;
  Stream<PlaybackState> get playbackStateStream => audioHandler.playbackState;
  Stream<List<MediaItem>> get queueStream => audioHandler.queue;
  Stream<PositionData> get positionDataStream => audioHandler.positionDataStream;

  MediaItem? get currentMediaItem => audioHandler.mediaItem.valueOrNull;
  bool get isPlaying => audioHandler.playbackState.valueOrNull?.playing ?? false;
  bool get hasQueue => (audioHandler.queue.valueOrNull?.isNotEmpty ?? false);
  String? get currentSongId => audioHandler.currentSongId;
  SongModel? get currentSong {
    final id = currentSongId;
    return id == null ? null : _songRepository.getById(id);
  }

  bool get shuffleEnabled => _shuffleEnabled;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
  double get speed => _speed;
  bool get hasSleepTimer => _sleepTimer != null;
  Duration? get sleepTimerRemaining =>
      _sleepTimerEndsAt == null ? null : _sleepTimerEndsAt!.difference(DateTime.now());

  void _bootstrap() {
    _shuffleEnabled = _settings.shuffleEnabled;
    _repeatMode = _parseRepeatMode(_settings.repeatMode);
    _speed = _settings.playbackSpeed;

    unawaited(audioHandler.setSpeed(_speed));
    unawaited(audioHandler.setRepeatMode(_repeatMode));
    unawaited(audioHandler
        .setShuffleMode(_shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none));

    _mediaItemSub = audioHandler.mediaItem.listen((_) {
      notifyListeners();
      unawaited(_maybeRecordPlay());
    });
    _playbackStateSub = audioHandler.playbackState.listen((state) {
      notifyListeners();
      if (state.playing) {
        unawaited(_persistSession());
      }
    });

    // Belt-and-braces: playbackState only fires on transitions, so this
    // keeps the persisted resume position fresh during long uninterrupted
    // playback too (not just at play/pause/skip events).
    _sessionPersistTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (isPlaying) unawaited(_persistSession());
    });
  }

  Future<void> _maybeRecordPlay() async {
    final id = audioHandler.currentSongId;
    if (id == null || id == _lastRecordedSongId) return;
    _lastRecordedSongId = id;
    await _historyRepository.recordPlay(id);
    await _songRepository.incrementPlayCount(id);
  }

  Future<void> playQueue(List<SongModel> songs, {int startIndex = 0}) {
    return audioHandler.loadQueue(songs, initialIndex: startIndex);
  }

  Future<void> playFromContext(SongModel song, List<SongModel> context) {
    final index = context.indexWhere((s) => s.id == song.id);
    return audioHandler.loadQueue(context, initialIndex: index < 0 ? 0 : index);
  }

  Future<void> togglePlayPause() {
    return isPlaying ? audioHandler.pause() : audioHandler.play();
  }

  Future<void> next() => audioHandler.skipToNext();
  Future<void> previous() => audioHandler.skipToPrevious();
  Future<void> seek(Duration position) => audioHandler.seek(position);
  Future<void> seekToQueueIndex(int index) => audioHandler.skipToQueueItem(index);
  Future<void> removeFromQueue(int index) => audioHandler.removeQueueItemAt(index);
  Future<void> playNext(SongModel song) => audioHandler.playNext(song);
  Future<void> addToQueue(SongModel song) => audioHandler.addToQueueEnd([song]);

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await audioHandler
        .setShuffleMode(_shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    await _settings.setShuffleEnabled(_shuffleEnabled);
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    final next = switch (_repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };
    _repeatMode = next;
    await audioHandler.setRepeatMode(next);
    await _settings.setRepeatMode(_repeatModeToString(next));
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await audioHandler.setSpeed(speed);
    await _settings.setPlaybackSpeed(speed);
    notifyListeners();
  }

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerEndsAt = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () async {
      await audioHandler.pause();
      _sleepTimer = null;
      _sleepTimerEndsAt = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndsAt = null;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final ids = audioHandler.queue.valueOrNull
            ?.map((m) => m.extras?['songId'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    if (ids.isEmpty) return;
    await _settings.saveLastSession(
      queueIds: ids,
      index: audioHandler.currentIndex ?? 0,
      positionMs: audioHandler.player.position.inMilliseconds,
    );
  }

  Future<void> restoreLastSession(List<SongModel> library) async {
    final ids = _settings.lastQueueIds;
    if (ids.isEmpty) return;

    final songs = ids.map((id) => library.firstWhereOrNull((s) => s.id == id)).whereType<SongModel>().toList();
    if (songs.isEmpty) return;

    final index = _settings.lastQueueIndex.clamp(0, songs.length - 1);
    await audioHandler.loadQueue(songs, initialIndex: index, autoplay: false);
    await audioHandler.seek(Duration(milliseconds: _settings.lastPositionMs));
  }

  AudioServiceRepeatMode _parseRepeatMode(String value) => switch (value) {
        'one' => AudioServiceRepeatMode.one,
        'all' => AudioServiceRepeatMode.all,
        _ => AudioServiceRepeatMode.none,
      };

  String _repeatModeToString(AudioServiceRepeatMode mode) => switch (mode) {
        AudioServiceRepeatMode.one => 'one',
        AudioServiceRepeatMode.all => 'all',
        _ => 'off',
      };

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sessionPersistTimer?.cancel();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    super.dispose();
  }
}
