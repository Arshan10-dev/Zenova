import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/album_art.dart';
import '../../widgets/Zenova_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/song_actions_sheet.dart';
import '../../widgets/song_tile.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumKey;
  const AlbumDetailScreen({super.key, required this.albumKey});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final album = library.albums.firstWhereOrNull((a) => a.key == albumKey);
    final theme = Theme.of(context);

    if (album == null) {
      return const ZenovaScaffold(body: EmptyState(icon: Icons.album_outlined, title: 'Album not found', message: ''));
    }

    return ZenovaScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
              title: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: Container(
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 56),
                child: Center(child: AlbumArt(audioId: album.coverSong.audioId, size: 180, borderRadius: 20, fallbackIcon: Icons.album_rounded)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.artist, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('${pluralize(album.songCount, 'song')} · ${formatDuration(album.totalDurationMs)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.read<PlayerProvider>().playQueue(album.songs),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final player = context.read<PlayerProvider>();
                            await player.playQueue(album.songs);
                            await player.toggleShuffle();
                          },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 160),
            sliver: SliverList.builder(
              itemCount: album.songs.length,
              itemBuilder: (context, index) {
                final song = album.songs[index];
                return SongTile(
                  song: song,
                  onTap: () => context.read<PlayerProvider>().playFromContext(song, album.songs),
                  onToggleFavorite: () => context.read<LibraryProvider>().toggleFavorite(song.id),
                  onMore: () => showSongOptionsSheet(context, song),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
