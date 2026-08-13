import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song_model.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import 'empty_state.dart';
import 'song_actions_sheet.dart';
import 'song_tile.dart';

class LibrarySearchDelegate extends SearchDelegate<void> {
  LibrarySearchDelegate() : super(searchFieldLabel: 'Search songs, artists, albums');

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Search your library',
        message: 'Find songs by title, artist, or album.',
      );
    }

    final library = context.watch<LibraryProvider>();
    final q = query.trim().toLowerCase();
    final results = library.allSongs
        .where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q) || s.album.toLowerCase().contains(q))
        .toList();

    if (results.isEmpty) {
      return EmptyState(icon: Icons.search_off_rounded, title: 'No results', message: 'Nothing matches "$query".');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return SongTile(
          song: song,
          showAlbum: true,
          onTap: () => _play(context, song, results),
          onToggleFavorite: () => context.read<LibraryProvider>().toggleFavorite(song.id),
          onMore: () => showSongOptionsSheet(context, song),
        );
      },
    );
  }

  void _play(BuildContext context, SongModel song, List<SongModel> results) {
    context.read<PlayerProvider>().playFromContext(song, results);
  }
}
