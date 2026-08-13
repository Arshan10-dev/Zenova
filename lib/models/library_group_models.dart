import 'song_model.dart';

/// Songs grouped by album — computed on the fly, not persisted separately.
class AlbumInfo {
  final String name;
  final String artist;
  final List<SongModel> songs;

  AlbumInfo({required this.name, required this.artist, required this.songs});

  int get songCount => songs.length;
  int get totalDurationMs => songs.fold(0, (sum, s) => sum + s.duration);
  SongModel get coverSong => songs.first;
  String get key => '$name|$artist';
}

class ArtistInfo {
  final String name;
  final List<SongModel> songs;

  ArtistInfo({required this.name, required this.songs});

  int get songCount => songs.length;
  Set<String> get albumNames => songs.map((s) => s.album).toSet();
  int get albumCount => albumNames.length;
  SongModel get coverSong => songs.first;
}

class FolderInfo {
  final String path;
  final String name;
  final List<SongModel> songs;

  FolderInfo({required this.path, required this.name, required this.songs});

  int get songCount => songs.length;
}
