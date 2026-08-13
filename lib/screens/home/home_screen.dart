import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../../providers/history_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/library_search_delegate.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/section_header.dart';
import '../../widgets/song_card.dart';
import '../favorites/favorites_screen.dart';
import '../playlists/playlist_detail_screen.dart';
import '../playlists/playlists_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch(context: context, delegate: LibrarySearchDelegate()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(context, library),
    );
  }

  Widget _buildBody(BuildContext context, LibraryProvider library) {
    if (library.isScanning && library.allSongs.isEmpty) {
      return const ShimmerList();
    }

    if (library.allSongs.isEmpty) {
      return EmptyState(
        icon: Icons.library_music_outlined,
        title: 'Your library is empty',
        message: library.lastError ?? 'Scan your device for music, or add songs manually from the Songs tab.',
        actionLabel: 'Scan for Music',
        onAction: () => context.read<LibraryProvider>().scanLibrary(),
      );
    }

    final recentlyPlayed = context.watch<HistoryProvider>().recentlyPlayed(limit: AppConstants.homeSectionItemLimit);
    final mostPlayed = library.mostPlayed;
    final favorites = library.favorites;
    final recentlyAdded = library.recentlyAdded;
    final playlists = context.watch<PlaylistProvider>().playlists;

    return RefreshIndicator(
      onRefresh: () => context.read<LibraryProvider>().scanLibrary(),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 160),
        children: [
          if (recentlyPlayed.isNotEmpty) ...[
            const SectionHeader(title: 'Recently Played'),
            _SongRow(songs: recentlyPlayed),
            const SizedBox(height: 20),
          ],
          if (mostPlayed.isNotEmpty) ...[
            const SectionHeader(title: 'Most Played'),
            _SongRow(songs: mostPlayed),
            const SizedBox(height: 20),
          ],
          if (favorites.isNotEmpty) ...[
            SectionHeader(
              title: 'Favorites',
              onSeeAll: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
            ),
            _SongRow(songs: favorites.take(AppConstants.homeSectionItemLimit).toList(), playContext: favorites),
            const SizedBox(height: 20),
          ],
          if (recentlyAdded.isNotEmpty) ...[
            const SectionHeader(title: 'Recently Added'),
            _SongRow(songs: recentlyAdded),
            const SizedBox(height: 20),
          ],
          SectionHeader(
            title: 'Playlists',
            onSeeAll: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlaylistsScreen())),
          ),
          _PlaylistRow(playlists: playlists),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  final List<SongModel> songs;
  final List<SongModel>? playContext;

  const _SongRow({required this.songs, this.playContext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongCard(song: song, onTap: () => context.read<PlayerProvider>().playFromContext(song, playContext ?? songs));
        },
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final List<PlaylistModel> playlists;
  const _PlaylistRow({required this.playlists});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('No playlists yet. Create one from the Playlists screen.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }
    return SizedBox(
      height: 128,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlist.id))),
            child: Container(
              width: 128,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.queue_music_rounded, color: theme.colorScheme.primary),
                  Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${playlist.songIds.length} songs', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
