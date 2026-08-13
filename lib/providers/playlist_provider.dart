import 'package:flutter/foundation.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../repository/playlist_repository.dart';
import '../repository/song_repository.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _repository;
  final SongRepository _songRepository;

  PlaylistProvider(this._repository, this._songRepository) {
    _playlists = _repository.getAll();
  }

  List<PlaylistModel> _playlists = [];
  List<PlaylistModel> get playlists => _playlists;

  PlaylistModel? getById(String id) => _repository.getById(id);

  List<SongModel> songsFor(PlaylistModel playlist) {
    return playlist.songIds.map(_songRepository.getById).whereType<SongModel>().toList();
  }

  Future<PlaylistModel> createPlaylist(String name) async {
    final playlist = await _repository.create(name);
    _refresh();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _repository.rename(id, newName);
    _refresh();
  }

  Future<void> deletePlaylist(String id) async {
    await _repository.delete(id);
    _refresh();
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    _refresh();
  }

  Future<void> addSongs(String playlistId, List<String> songIds) async {
    await _repository.addSongs(playlistId, songIds);
    _refresh();
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await _repository.removeSong(playlistId, songId);
    _refresh();
  }

  Future<void> reorderSongs(String playlistId, List<String> newOrder) async {
    await _repository.reorderSongs(playlistId, newOrder);
    _refresh();
  }

  void _refresh() {
    _playlists = _repository.getAll();
    notifyListeners();
  }
}
