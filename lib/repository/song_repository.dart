import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/song_model.dart';
import '../services/hive_service.dart';

class SongRepository {
  Box<SongModel> get _box => HiveService.songsBox;

  List<SongModel> getAll() => _box.values.toList();
  SongModel? getById(String id) => _box.get(id);

  Future<void> put(SongModel song) => _box.put(song.id, song);
  Future<void> putAll(Iterable<SongModel> songs) => _box.putAll({for (final s in songs) s.id: s});
  Future<void> delete(String id) => _box.delete(id);
  Future<void> deleteMany(Iterable<String> ids) => _box.deleteAll(ids);

  /// Merges a fresh device scan into the existing library: songs already
  /// known keep their favorite flag / play count; songs no longer found on
  /// disk (and not manually imported) are removed; new songs are added.
  Future<void> mergeScanResults(List<SongModel> scanned) async {
    final existing = {for (final s in _box.values) s.id: s};
    final scannedIds = scanned.map((s) => s.id).toSet();

    final toWrite = <String, SongModel>{};
    for (final song in scanned) {
      final prior = existing[song.id];
      if (prior != null) {
        toWrite[song.id] = song.copyWith(isFavorite: prior.isFavorite, playCount: prior.playCount);
      } else {
        toWrite[song.id] = song;
      }
    }
    await _box.putAll(toWrite);

    final staleIds =
        existing.keys.where((id) => !scannedIds.contains(id) && existing[id]!.isManual == false).toList();
    if (staleIds.isNotEmpty) {
      await _box.deleteAll(staleIds);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final song = _box.get(id);
    if (song == null) return;
    song.isFavorite = !song.isFavorite;
    await song.save();
  }

  Future<void> incrementPlayCount(String id) async {
    final song = _box.get(id);
    if (song == null) return;
    song.playCount += 1;
    await song.save();
  }
}
