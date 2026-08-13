import 'package:hive_ce/hive_ce.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> songIds;

  @HiveField(3)
  int createdAt;

  @HiveField(4)
  bool isFavorite;

  PlaylistModel({
    required this.id,
    required this.name,
    List<String>? songIds,
    required this.createdAt,
    this.isFavorite = false,
  }) : songIds = songIds ?? [];

  @override
  bool operator ==(Object other) => other is PlaylistModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
