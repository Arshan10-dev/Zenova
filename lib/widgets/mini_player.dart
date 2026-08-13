import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../providers/player_provider.dart';
import '../services/audio_handler.dart';
import 'album_art.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onExpand;

  const MiniPlayer({super.key, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final mediaItem = player.currentMediaItem;
    if (mediaItem == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final audioId = mediaItem.extras?['audioId'] as int?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GestureDetector(
        onTap: onExpand,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -250) {
            player.next();
          } else if (velocity > 250) {
            player.previous();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: AppConstants.miniPlayerHeight,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Hero(tag: 'now-playing-art', child: AlbumArt(audioId: audioId, size: 44, borderRadius: 10)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(mediaItem.artist ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        StreamBuilder<PlaybackState>(
                          stream: player.playbackStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            final procState = snapshot.data?.processingState;
                            final loading =
                                procState == AudioProcessingState.loading || procState == AudioProcessingState.buffering;
                            return IconButton(
                              iconSize: 30,
                              icon: loading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.primary))
                                  : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              onPressed: player.togglePlayPause,
                            );
                          },
                        ),
                        IconButton(iconSize: 26, icon: const Icon(Icons.skip_next_rounded), onPressed: player.next),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                      child: StreamBuilder<PositionData>(
                        stream: player.positionDataStream,
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          final total = data?.duration.inMilliseconds ?? 0;
                          final progress = total > 0 ? (data!.position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
                          return LinearProgressIndicator(
                            value: progress,
                            minHeight: 2.5,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(scheme.primary),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
