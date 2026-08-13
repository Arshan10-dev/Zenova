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

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final artist = library.artists.firstWhereOrNull((a) => a.name == artistName);
    final theme = Theme.of(context);

    if (artist == null) {
      return const ZenovaScaffold(body: EmptyState(icon: Icons.person_outline_rounded, title: 'Artist not found', message: ''));
    }

    return ZenovaScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
              title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: Container(
                color: theme.colorScheme.surfaceContainer,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 56),
                child: Center(child: ClipOval(child: AlbumArt(audioId: artist.coverSong.audioId, size: 160, borderRadius: 0, fallbackIcon: Icons.person_rounded))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${pluralize(artist.albumCount, 'album')} · ${pluralize(artist.songCount, 'song')}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.read<PlayerProvider>().playQueue(artist.songs),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final player = context.read<PlayerProvider>();
                            await player.playQueue(artist.songs);
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
              itemCount: artist.songs.length,
              itemBuilder: (context, index) {
                final song = artist.songs[index];
                return SongTile(
                  song: song,
                  showAlbum: true,
                  onTap: () => context.read<PlayerProvider>().playFromContext(song, artist.songs),
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
