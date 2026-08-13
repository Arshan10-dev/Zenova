import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/cadence_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/song_actions_sheet.dart';
import '../../widgets/song_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final favorites = library.favorites;

    return CadenceScaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const EmptyState(icon: Icons.favorite_border_rounded, title: 'No favorites yet', message: 'Tap the heart on any song to add it here.')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 160, top: 4),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final song = favorites[index];
                return SongTile(
                  song: song,
                  showAlbum: true,
                  onTap: () => context.read<PlayerProvider>().playFromContext(song, favorites),
                  onToggleFavorite: () => context.read<LibraryProvider>().toggleFavorite(song.id),
                  onMore: () => showSongOptionsSheet(context, song),
                );
              },
            ),
    );
  }
}
