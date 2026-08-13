import 'dart:io';
import 'dart:typed_data';

import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

/// Extracts embedded album art via MediaStore and caches it to disk as JPEGs
/// so audio_service can hand the system a `file://` URI for the playback
/// notification and lock screen.
class ArtworkService {
  ArtworkService._();

  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static final Map<int, Uri?> _uriCache = {};
  static Directory? _artDir;

  static Future<Directory> _ensureArtDir() async {
    if (_artDir != null) return _artDir!;
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/cadence_artwork');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _artDir = dir;
    return dir;
  }

  static Future<Uri?> artUriFor(int? audioId) async {
    if (audioId == null) return null;
    if (_uriCache.containsKey(audioId)) return _uriCache[audioId];

    try {
      final dir = await _ensureArtDir();
      final file = File('${dir.path}/$audioId.jpg');

      if (await file.exists() && await file.length() > 0) {
        final uri = Uri.file(file.path);
        _uriCache[audioId] = uri;
        return uri;
      }

      final bytes = await _audioQuery.queryArtwork(
        audioId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 500,
        quality: 90,
      );

      if (bytes == null || bytes.isEmpty) {
        _uriCache[audioId] = null;
        return null;
      }

      await file.writeAsBytes(bytes, flush: true);
      final uri = Uri.file(file.path);
      _uriCache[audioId] = uri;
      return uri;
    } catch (_) {
      _uriCache[audioId] = null;
      return null;
    }
  }

  static Future<Uint8List?> artworkBytes(int? audioId, {int size = 400}) async {
    if (audioId == null) return null;
    try {
      return await _audioQuery.queryArtwork(audioId, ArtworkType.AUDIO, format: ArtworkFormat.JPEG, size: size);
    } catch (_) {
      return null;
    }
  }

  static void clearMemoryCache() => _uriCache.clear();
}
