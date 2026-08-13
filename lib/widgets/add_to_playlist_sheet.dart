import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../providers/playlist_provider.dart';

Future<void> showAddToPlaylistSheet(BuildContext context, List<String> songIds) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddToPlaylistSheet(songIds: songIds),
  );
}

Future<String?> promptForPlaylistName(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String confirmLabel = 'Create',
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onSubmitted: (value) => Navigator.pop(dialogContext, value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class _AddToPlaylistSheet extends StatelessWidget {
  final List<String> songIds;
  const _AddToPlaylistSheet({required this.songIds});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Add to Playlist', style: theme.textTheme.titleMedium),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
              ),
              title: const Text('New Playlist'),
              onTap: () => _createAndAdd(context),
            ),
            const Divider(height: 1),
            Flexible(
              child: playlistProvider.playlists.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text('No playlists yet — create one above.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: playlistProvider.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistProvider.playlists[index];
                        final alreadyContainsAll = songIds.every((id) => playlist.songIds.contains(id));
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
                            child: Icon(Icons.queue_music_rounded, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          title: Text(playlist.name),
                          subtitle: Text(pluralize(playlist.songIds.length, 'song')),
                          trailing:
                              alreadyContainsAll ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
                          onTap: () async {
                            final playlistProvider = context.read<PlaylistProvider>();
                            await playlistProvider.addSongs(playlist.id, songIds);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(content: Text('Added to ${playlist.name}')));
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final playlistProvider = context.read<PlaylistProvider>();
    final name = await promptForPlaylistName(context, title: 'New Playlist');
    if (name == null || name.trim().isEmpty) return;

    final playlist = await playlistProvider.createPlaylist(name.trim());
    await playlistProvider.addSongs(playlist.id, songIds);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Created "${playlist.name}"')));
    }
  }
}
