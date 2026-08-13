import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/cadence_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/song_actions_sheet.dart';
import '../../widgets/song_tile.dart';

class FolderDetailScreen extends StatelessWidget {
  final String folderPath;
  const FolderDetailScreen({super.key, required this.folderPath});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final folder = library.folders.firstWhereOrNull((f) => f.path == folderPath);

    if (folder == null) {
      return const CadenceScaffold(body: EmptyState(icon: Icons.folder_outlined, title: 'Folder not found', message: ''));
    }

    return CadenceScaffold(
      appBar: AppBar(title: Text(folder.name)),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 160, top: 4),
        itemCount: folder.songs.length,
        itemBuilder: (context, index) {
          final song = folder.songs[index];
          return SongTile(
            song: song,
            showAlbum: true,
            onTap: () => context.read<PlayerProvider>().playFromContext(song, folder.songs),
            onToggleFavorite: () => context.read<LibraryProvider>().toggleFavorite(song.id),
            onMore: () => showSongOptionsSheet(context, song),
          );
        },
      ),
    );
  }
}
