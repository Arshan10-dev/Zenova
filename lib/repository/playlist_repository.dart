import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/playlist_model.dart';
import '../services/hive_service.dart';

class PlaylistRepository {
  Box<PlaylistModel> get _box => HiveService.playlistsBox;

  List<PlaylistModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  PlaylistModel? getById(String id) => _box.get(id);

  Future<PlaylistModel> create(String name) async {
    final playlist = PlaylistModel(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _box.put(playlist.id, playlist);
    return playlist;
  }

  Future<void> rename(String id, String newName) async {
    final playlist = _box.get(id);
    if (playlist == null) return;
    playlist.name = newName.trim();
    await playlist.save();
  }

  Future<void> delete(String id) => _box.delete(id);

  Future<void> toggleFavorite(String id) async {
    final playlist = _box.get(id);
    if (playlist == null) return;
    playlist.isFavorite = !playlist.isFavorite;
    await playlist.save();
  }

  Future<void> addSongs(String playlistId, List<String> songIds) async {
    final playlist = _box.get(playlistId);
    if (playlist == null) return;
    final existing = playlist.songIds.toSet();
    final toAdd = songIds.where((id) => !existing.contains(id));
    playlist.songIds = [...playlist.songIds, ...toAdd];
    await playlist.save();
  }

  Future<void> removeSong(String playlistId, String songId) async {
    final playlist = _box.get(playlistId);
    if (playlist == null) return;
    playlist.songIds = playlist.songIds.where((id) => id != songId).toList();
    await playlist.save();
  }

  Future<void> reorderSongs(String playlistId, List<String> newOrder) async {
    final playlist = _box.get(playlistId);
    if (playlist == null) return;
    playlist.songIds = newOrder;
    await playlist.save();
  }
}
