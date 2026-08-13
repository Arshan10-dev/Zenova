import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/library_group_models.dart';
import 'album_art.dart';

class AlbumGridCard extends StatelessWidget {
  final AlbumInfo album;
  final VoidCallback onTap;

  const AlbumGridCard({super.key, required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AlbumArt(audioId: album.coverSong.audioId, size: double.infinity, borderRadius: 16, fallbackIcon: Icons.album_rounded),
          ),
          const SizedBox(height: 8),
          Text(album.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text('${album.artist} · ${pluralize(album.songCount, 'song')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class ArtistGridCard extends StatelessWidget {
  final ArtistInfo artist;
  final VoidCallback onTap;

  const ArtistGridCard({super.key, required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipOval(
              child: AlbumArt(audioId: artist.coverSong.audioId, size: double.infinity, borderRadius: 0, fallbackIcon: Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Text(artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(pluralize(artist.songCount, 'song'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
