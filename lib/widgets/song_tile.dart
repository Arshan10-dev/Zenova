import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/song_model.dart';
import 'album_art.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final bool selected;
  final bool selectionMode;
  final bool showAlbum;
  final bool isCurrent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onMore;

  const SongTile({
    super.key,
    required this.song,
    this.selected = false,
    this.selectionMode = false,
    this.showAlbum = false,
    this.isCurrent = false,
    this.onTap,
    this.onLongPress,
    this.onToggleFavorite,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _leading(scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      showAlbum ? '${song.artist} • ${song.album}' : song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!selectionMode) ...[
                Text(formatDuration(song.duration),
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: song.isFavorite ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleFavorite,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: scheme.onSurfaceVariant),
                  onPressed: onMore,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading(ColorScheme scheme) {
    if (!selectionMode) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AlbumArt(audioId: song.audioId, size: 48, borderRadius: 10),
          if (isCurrent)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: Icon(Icons.graphic_eq_rounded, color: scheme.primary, size: 20),
            ),
        ],
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.35, child: AlbumArt(audioId: song.audioId, size: 48, borderRadius: 10)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primary : scheme.surface.withValues(alpha: 0.85),
              border: Border.all(color: selected ? scheme.primary : scheme.onSurfaceVariant, width: 2),
            ),
            child: selected ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary) : null,
          ),
        ],
      ),
    );
  }
}
