import 'package:hive_ce/hive_ce.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String artist;

  @HiveField(3)
  String album;

  @HiveField(4)
  String path;

  @HiveField(5)
  int duration;

  @HiveField(6)
  int size;

  @HiveField(7)
  int dateAdded;

  @HiveField(8)
  bool isFavorite;

  @HiveField(9)
  int playCount;

  @HiveField(10)
  int? audioId;

  @HiveField(11)
  bool isManual;

  @HiveField(12)
  String folderPath;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    required this.size,
    required this.dateAdded,
    required this.folderPath,
    this.isFavorite = false,
    this.playCount = 0,
    this.audioId,
    this.isManual = false,
  });

  SongModel copyWith({
    String? title,
    String? artist,
    String? album,
    bool? isFavorite,
    int? playCount,
    int? audioId,
  }) {
    return SongModel(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path,
      duration: duration,
      size: size,
      dateAdded: dateAdded,
      folderPath: folderPath,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      audioId: audioId ?? this.audioId,
      isManual: isManual,
    );
  }

  @override
  bool operator ==(Object other) => other is SongModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
