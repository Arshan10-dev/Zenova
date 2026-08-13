import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';
import '../models/song_model.dart';
import 'music_scanner_service.dart';

class FileImportResult {
  final List<SongModel> songs;
  final List<String> skippedFileNames;
  FileImportResult({required this.songs, required this.skippedFileNames});

  bool get hasSkipped => skippedFileNames.isNotEmpty;
}

/// Powers the "+ Add Songs" flow: user picks files/folders, we resolve each
/// one to a full SongModel using a three-tier strategy (see [_resolveSong]).
class FileImportService {
  final MusicScannerService _scanner;
  FileImportService(this._scanner);

  Future<List<String>?> pickAudioFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedExtensions,
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return null;
    return result.paths.whereType<String>().toList();
  }

  Future<String?> pickFolder() => FilePicker.getDirectoryPath();

  Future<List<String>> collectAudioFilesInFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];
    final found = <String>[];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && isSupportedAudioFile(entity.path)) {
          found.add(entity.path);
        }
      }
    } catch (_) {
      // Permission-restricted subfolder etc. — return whatever we found.
    }
    return found;
  }

  Future<FileImportResult> importPaths(List<String> paths) async {
    final songs = <SongModel>[];
    final skipped = <String>[];

    for (final path in paths) {
      try {
        if (!isSupportedAudioFile(path)) {
          skipped.add(p.basename(path));
          continue;
        }
        final song = await _resolveSong(path);
        if (song != null) {
          songs.add(song);
        } else {
          skipped.add(p.basename(path));
        }
      } catch (_) {
        skipped.add(p.basename(path));
      }
    }

    return FileImportResult(songs: songs, skippedFileNames: skipped);
  }

  Future<SongModel?> _resolveSong(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    var match = await _scanner.findByPath(path);

    if (match == null) {
      await _scanner.requestMediaScan(path);
      await Future.delayed(const Duration(milliseconds: 600));
      match = await _scanner.findByPath(path);
    }

    if (match != null) {
      return _scanner.toSongModel(match, isManual: true);
    }

    return _buildFallbackSong(path, file);
  }

  Future<SongModel?> _buildFallbackSong(String path, File file) async {
    int durationMs;
    final tempPlayer = AudioPlayer();
    try {
      final duration = await tempPlayer.setFilePath(path);
      durationMs = duration?.inMilliseconds ?? 0;
    } catch (_) {
      return null;
    } finally {
      unawaited(tempPlayer.dispose());
    }

    if (durationMs <= 0) return null;

    final size = await file.length();

    return SongModel(
      id: 'manual_${const Uuid().v4()}',
      title: titleFromFileName(path),
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      path: path,
      duration: durationMs,
      size: size,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      folderPath: parentFolderPath(path),
      audioId: null,
      isManual: true,
    );
  }
}
