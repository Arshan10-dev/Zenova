import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/playlist_provider.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../widgets/cadence_scaffold.dart';
import '../../widgets/empty_state.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistProvider>().playlists;
    final theme = Theme.of(context);

    return CadenceScaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlaylist(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Playlist'),
      ),
      body: playlists.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_rounded,
              title: 'No playlists yet',
              message: 'Create a playlist to start organizing your music.',
              actionLabel: 'New Playlist',
              onAction: () => _createPlaylist(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 160, top: 4),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(Icons.queue_music_rounded, color: theme.colorScheme.primary),
                  ),
                  title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${playlist.songIds.length} songs'),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) => _handleMenuAction(context, value, playlist.id, playlist.name),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(children: [
                          Icon(playlist.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(playlist.isFavorite ? 'Unfavorite' : 'Favorite'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Rename'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Delete'),
                        ]),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlist.id)),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await promptForPlaylistName(context, title: 'New Playlist');
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await context.read<PlaylistProvider>().createPlaylist(name.trim());
  }

  void _handleMenuAction(BuildContext context, String action, String playlistId, String currentName) {
    final provider = context.read<PlaylistProvider>();
    switch (action) {
      case 'favorite':
        provider.toggleFavorite(playlistId);
      case 'rename':
        _renamePlaylist(context, playlistId, currentName);
      case 'delete':
        _confirmDelete(context, playlistId, currentName);
    }
  }

  Future<void> _renamePlaylist(BuildContext context, String playlistId, String currentName) async {
    final name = await promptForPlaylistName(
      context,
      title: 'Rename Playlist',
      initialValue: currentName,
      confirmLabel: 'Save',
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await context.read<PlaylistProvider>().renamePlaylist(playlistId, name.trim());
  }

  void _confirmDelete(BuildContext context, String playlistId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text('"$name" will be deleted. Your songs won\'t be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<PlaylistProvider>().deletePlaylist(playlistId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
