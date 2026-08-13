import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/player_provider.dart';
import '../../widgets/album_art.dart';

Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    builder: (_) => const _QueueSheet(),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return StreamBuilder<List<MediaItem>>(
          stream: player.queueStream,
          builder: (context, queueSnapshot) {
            final queue = queueSnapshot.data ?? const <MediaItem>[];
            return StreamBuilder<PlaybackState>(
              stream: player.playbackStateStream,
              builder: (context, stateSnapshot) {
                final currentIndex = stateSnapshot.data?.queueIndex ?? 0;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Queue', style: theme.textTheme.titleMedium),
                          Text(pluralize(queue.length, 'song'), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: queue.isEmpty
                          ? Center(child: Text('Queue is empty', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: queue.length,
                              itemBuilder: (context, index) {
                                final item = queue[index];
                                final isCurrent = index == currentIndex;
                                final audioId = item.extras?['audioId'] as int?;
                                return Dismissible(
                                  key: ValueKey('${item.id}_$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    color: theme.colorScheme.error.withValues(alpha: 0.15),
                                    child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                                  ),
                                  onDismissed: (_) => context.read<PlayerProvider>().removeFromQueue(index),
                                  child: ListTile(
                                    leading: AlbumArt(audioId: audioId, size: 44, borderRadius: 10),
                                    title: Text(item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.w600, color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
                                    subtitle: Text(item.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: isCurrent
                                        ? Icon(Icons.graphic_eq_rounded, color: theme.colorScheme.primary, size: 20)
                                        : Text(formatDurationFromDuration(item.duration ?? Duration.zero)),
                                    onTap: () => context.read<PlayerProvider>().seekToQueueIndex(index),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
