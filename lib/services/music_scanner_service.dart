import 'package:on_audio_query_pluse/on_audio_query.dart' as oaq;

import '../core/utils/file_utils.dart';
import '../models/song_model.dart';

/// Wraps on_audio_query_pluse for the "automatic scan" import path.
class MusicScannerService {
  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();

  Future<bool> hasPermission() => _audioQuery.permissionsStatus();
  Future<bool> requestPermission() => _audioQuery.permissionsRequest();

  Future<List<SongModel>> scanDevice() async {
    final raw = await _audioQuery.querySongs(
      sortType: oaq.SongSortType.TITLE,
      orderType: oaq.OrderType.ASC_OR_SMALLER,
      uriType: oaq.UriType.EXTERNAL,
      ignoreCase: true,
    );

    final songs = <SongModel>[];
    for (final s in raw) {
      final song = toSongModel(s);
      if (song != null) songs.add(song);
    }
    return songs;
  }

  Future<oaq.SongModel?> findByPath(String path) async {
    final all = await _audioQuery.querySongs(uriType: oaq.UriType.EXTERNAL);
    for (final s in all) {
      if (s.data == path) return s;
    }
    return null;
  }

  Future<void> requestMediaScan(String path) async {
    try {
      await _audioQuery.scanMedia(path);
    } catch (_) {
      // Best-effort: some OEM ROMs restrict MediaScanner triggers.
    }
  }

  SongModel? toSongModel(oaq.SongModel s, {bool isManual = false}) {
    if (s.data.isEmpty || !isSupportedAudioFile(s.data)) return null;
    if ((s.duration ?? 0) <= 0) return null;

    final artist =
        (s.artist == null || s.artist!.isEmpty || s.artist == '<unknown>') ? 'Unknown Artist' : s.artist!;
    final album =
        (s.album == null || s.album!.isEmpty || s.album == '<unknown>') ? 'Unknown Album' : s.album!;

    return SongModel(
      id: 'audio_${s.id}',
      title: s.title.isNotEmpty ? s.title : titleFromFileName(s.data),
      artist: artist,
      album: album,
      path: s.data,
      duration: s.duration ?? 0,
      size: s.size,
      // MediaStore's DATE_ADDED column is in seconds, not milliseconds.
      dateAdded: (s.dateAdded ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000,
      folderPath: parentFolderPath(s.data),
      audioId: s.id,
      isManual: isManual,
    );
  }
}
