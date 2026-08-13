import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../models/song_model.dart';
import 'artwork_service.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  const PositionData(this.position, this.bufferedPosition, this.duration);
}

/// Cadence's single AudioHandler. QueueHandler gives us default
/// queue-manipulation behavior; SeekHandler gives us fast-forward/rewind
/// built on top of [seek].
class CadenceAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  List<String> _queueSongIds = [];

  CadenceAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    await player.setAudioSource(_playlist);

    player.playbackEventStream.listen(
      (event) => playbackState.add(_transformEvent(event)),
      onError: (Object e, StackTrace st) {
        playbackState.add(
          playbackState.value.copyWith(processingState: AudioProcessingState.error, playing: false),
        );
      },
    );

    player.currentIndexStream.listen((index) {
      if (index == null) return;
      final q = queue.value;
      if (index >= 0 && index < q.length) {
        mediaItem.add(q[index]);
        unawaited(_resolveArtworkFor(index));
      }
    });
  }

  Future<void> loadQueue(List<SongModel> songs, {int initialIndex = 0, bool autoplay = true}) async {
    if (songs.isEmpty) return;

    _queueSongIds = songs.map((s) => s.id).toList();
    final items = songs.map(_toMediaItem).toList();
    queue.add(items);

    await _playlist.clear();
    await _playlist.addAll(songs.map(_toAudioSource).toList());

    final clampedIndex = initialIndex.clamp(0, songs.length - 1);
    await player.seek(Duration.zero, index: clampedIndex);
    unawaited(_resolveArtworkFor(clampedIndex));

    if (autoplay) {
      await player.play();
    }
  }

  Future<void> addToQueueEnd(List<SongModel> songs) async {
    if (songs.isEmpty) return;
    _queueSongIds.addAll(songs.map((s) => s.id));
    queue.add([...queue.value, ...songs.map(_toMediaItem)]);
    await _playlist.addAll(songs.map(_toAudioSource).toList());
  }

  Future<void> playNext(SongModel song) async {
    final insertAt = (player.currentIndex ?? -1) + 1;
    _queueSongIds.insert(insertAt, song.id);
    final item = _toMediaItem(song);
    final newQueue = [...queue.value]..insert(insertAt, item);
    queue.add(newQueue);
    await _playlist.insert(insertAt, _toAudioSource(song));
  }

  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    _queueSongIds.removeAt(index);
    final newQueue = [...queue.value]..removeAt(index);
    queue.add(newQueue);
    await _playlist.removeAt(index);
  }

  String? get currentSongId {
    final index = player.currentIndex;
    if (index == null || index < 0 || index >= _queueSongIds.length) return null;
    return _queueSongIds[index];
  }

  int? get currentIndex => player.currentIndex;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, buffered, duration) => PositionData(position, buffered, duration ?? Duration.zero),
      );

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (player.hasNext) await player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (player.position > const Duration(seconds: 3) || !player.hasPrevious) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> stop() async {
    await player.stop();
    return super.stop();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    await player.setShuffleModeEnabled(enabled);
    if (enabled) await player.shuffle();
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await player.setLoopMode(LoopMode.off);
      case AudioServiceRepeatMode.one:
        await player.setLoopMode(LoopMode.one);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await player.setLoopMode(LoopMode.all);
    }
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  MediaItem _toMediaItem(SongModel song) {
    return MediaItem(
      id: song.path,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      extras: {'songId': song.id, 'audioId': song.audioId},
    );
  }

  AudioSource _toAudioSource(SongModel song) {
    return AudioSource.uri(Uri.file(song.path), tag: _toMediaItem(song));
  }

  Future<void> _resolveArtworkFor(int index) async {
    final q = queue.value;
    if (index < 0 || index >= q.length) return;
    final item = q[index];
    final audioId = item.extras?['audioId'] as int?;
    if (audioId == null) return;

    final uri = await ArtworkService.artUriFor(audioId);
    if (uri == null) return;
    if (player.currentIndex != index) return;

    final updated = item.copyWith(artUri: uri);
    mediaItem.add(updated);
    final newQueue = [...queue.value];
    if (index < newQueue.length) {
      newQueue[index] = updated;
      queue.add(newQueue);
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
