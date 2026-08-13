import 'package:flutter/material.dart';

import '../models/song_model.dart';
import 'album_art.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final double width;

  const SongCard({super.key, required this.song, required this.onTap, this.width = 136});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlbumArt(audioId: song.audioId, size: width - 12, borderRadius: 14),
              const SizedBox(height: 8),
              Text(song.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
