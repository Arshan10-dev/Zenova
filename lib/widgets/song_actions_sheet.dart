import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song_model.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import 'album_art.dart';
import 'add_to_playlist_sheet.dart';

/// Opens the standard song-options sheet. Pass [onRemoveFromPlaylist] when
/// called from inside a playlist so "Remove from this playlist" appears
/// alongside (not instead of) "Remove from Library".
Future<void> showSongOptionsSheet(BuildContext context, SongModel song, {VoidCallback? onRemoveFromPlaylist}) {
  final library = context.read<LibraryProvider>();
  final player = context.read<PlayerProvider>();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    AlbumArt(audioId: song.audioId, size: 48, borderRadius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                          Text(song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _SheetTile(
                icon: song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: song.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                iconColor: song.isFavorite ? theme.colorScheme.primary : null,
                onTap: () {
                  library.toggleFavorite(song.id);
                  Navigator.pop(sheetContext);
                },
              ),
              _SheetTile(
                icon: Icons.playlist_play_rounded,
                label: 'Play Next',
                onTap: () {
                  player.playNext(song);
                  Navigator.pop(sheetContext);
                  _toast(context, 'Playing next');
                },
              ),
              _SheetTile(
                icon: Icons.queue_music_rounded,
                label: 'Add to Queue',
                onTap: () {
                  player.addToQueue(song);
                  Navigator.pop(sheetContext);
                  _toast(context, 'Added to queue');
                },
              ),
              _SheetTile(
                icon: Icons.playlist_add_rounded,
                label: 'Add to Playlist',
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAddToPlaylistSheet(context, [song.id]);
                },
              ),
              if (onRemoveFromPlaylist != null)
                _SheetTile(
                  icon: Icons.playlist_remove_rounded,
                  label: 'Remove from this Playlist',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onRemoveFromPlaylist();
                  },
                ),
              _SheetTile(
                icon: Icons.delete_outline_rounded,
                label: 'Remove from Library',
                destructive: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmRemove(context, library, song);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _confirmRemove(BuildContext context, LibraryProvider library, SongModel song) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove from Library?'),
      content: Text('"${song.title}" will be removed from Zenova. This won\'t delete the file from your device.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            library.removeFromLibrary([song.id]);
            Navigator.pop(dialogContext);
          },
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool destructive;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : (iconColor ?? scheme.onSurfaceVariant);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: destructive ? scheme.error : scheme.onSurface)),
      onTap: onTap,
    );
  }
}
