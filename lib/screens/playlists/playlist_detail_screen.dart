import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/song_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/album_art.dart';
import '../../widgets/Zenova_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/song_actions_sheet.dart';
import '../../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final playlist = playlistProvider.playlists.firstWhereOrNull((p) => p.id == playlistId);
    final theme = Theme.of(context);

    if (playlist == null) {
      return const ZenovaScaffold(
        body: EmptyState(icon: Icons.queue_music_rounded, title: 'Playlist not found', message: ''),
      );
    }

    final songs = playlistProvider.songsFor(playlist);

    return ZenovaScaffold(
      appBar: AppBar(
        title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(playlist.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            onPressed: () => context.read<PlaylistProvider>().toggleFavorite(playlist.id),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add songs',
            onPressed: () => _openSongPicker(context, playlist.id, songs.map((s) => s.id).toSet()),
          ),
        ],
      ),
      body: songs.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_rounded,
              title: 'This playlist is empty',
              message: 'Add songs from your library to get started.',
              actionLabel: 'Add Songs',
              onAction: () => _openSongPicker(context, playlist.id, {}),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pluralize(songs.length, 'song'),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.read<PlayerProvider>().playQueue(songs),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Play'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final player = context.read<PlayerProvider>();
                          await player.playQueue(songs);
                          await player.toggleShuffle();
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 18),
                        label: const Text('Shuffle'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 160),
                    itemCount: songs.length,
                    onReorder: (oldIndex, newIndex) {
                      final newOrder = List<SongModel>.from(songs);
                      if (newIndex > oldIndex) newIndex -= 1;
                      final moved = newOrder.removeAt(oldIndex);
                      newOrder.insert(newIndex, moved);
                      context
                          .read<PlaylistProvider>()
                          .reorderSongs(playlist.id, newOrder.map((s) => s.id).toList());
                    },
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return SongTile(
                        key: ValueKey(song.id),
                        song: song,
                        showAlbum: true,
                        onTap: () => context.read<PlayerProvider>().playFromContext(song, songs),
                        onToggleFavorite: () => context.read<LibraryProvider>().toggleFavorite(song.id),
                        onMore: () => showSongOptionsSheet(
                          context,
                          song,
                          onRemoveFromPlaylist: () =>
                              context.read<PlaylistProvider>().removeSong(playlist.id, song.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _openSongPicker(BuildContext context, String playlistId, Set<String> alreadyIn) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SongPickerScreen(playlistId: playlistId, alreadyInPlaylist: alreadyIn),
      ),
    );
  }
}

class _SongPickerScreen extends StatefulWidget {
  final String playlistId;
  final Set<String> alreadyInPlaylist;
  const _SongPickerScreen({required this.playlistId, required this.alreadyInPlaylist});

  @override
  State<_SongPickerScreen> createState() => _SongPickerScreenState();
}

class _SongPickerScreenState extends State<_SongPickerScreen> {
  final Set<String> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final theme = Theme.of(context);
    final all = library.allSongs;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Songs'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () async {
                    await context.read<PlaylistProvider>().addSongs(widget.playlistId, _selected.toList());
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text('Add${_selected.isEmpty ? '' : ' (${_selected.length})'}'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Search your library',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainer),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final song = filtered[index];
                final alreadyIn = widget.alreadyInPlaylist.contains(song.id);
                final selected = _selected.contains(song.id);
                return ListTile(
                  leading: AlbumArt(audioId: song.audioId, size: 44, borderRadius: 10),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: alreadyIn
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.onSurfaceVariant)
                      : Checkbox(
                          value: selected,
                          onChanged: (_) => setState(() {
                            selected ? _selected.remove(song.id) : _selected.add(song.id);
                          }),
                        ),
                  onTap: alreadyIn
                      ? null
                      : () => setState(() {
                            selected ? _selected.remove(song.id) : _selected.add(song.id);
                          }),
                  enabled: !alreadyIn,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
