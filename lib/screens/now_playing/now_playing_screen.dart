import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/artwork_service.dart';
import '../../widgets/album_art.dart';
import '../../widgets/song_actions_sheet.dart';
import 'queue_sheet.dart';

Future<void> pushNowPlaying(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    ),
  );
}

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  Color? _dominantColor;
  int? _paletteAudioId;

  Future<void> _maybeUpdatePalette(int? audioId) async {
    if (audioId == _paletteAudioId) return;
    _paletteAudioId = audioId;
    if (audioId == null) {
      if (mounted) setState(() => _dominantColor = null);
      return;
    }
    final bytes = await ArtworkService.artworkBytes(audioId, size: 180);
    if (!mounted || bytes == null) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(MemoryImage(bytes), maximumColorCount: 12);
      if (!mounted || _paletteAudioId != audioId) return;
      setState(() {
        _dominantColor = palette.dominantColor?.color ?? palette.vibrantColor?.color;
      });
    } catch (_) {
      // Palette extraction is a nice-to-have; fall back to the theme color.
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<MediaItem?>(
      stream: player.mediaItemStream,
      initialData: player.currentMediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text('Nothing playing', style: theme.textTheme.bodyLarge)));
        }

        final audioId = mediaItem.extras?['audioId'] as int?;
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeUpdatePalette(audioId));
        final songId = mediaItem.extras?['songId'] as String?;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32), onPressed: () => Navigator.of(context).pop()),
            title: Text('PLAYING FROM LIBRARY', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: scheme.onSurfaceVariant)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                  if (songId == null) return;
                  final song = context.read<LibraryProvider>().getById(songId);
                  if (song != null) showSongOptionsSheet(context, song);
                },
              ),
            ],
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [(_dominantColor ?? scheme.primary).withValues(alpha: 0.32), scheme.surface, scheme.surface],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final artSize = (constraints.maxWidth - 56).clamp(220.0, 360.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Hero(
                              tag: 'now-playing-art',
                              child: AnimatedSwitcher(
                                duration: AppConstants.animMedium,
                                switchInCurve: Curves.easeOut,
                                child: Container(
                                  key: ValueKey(mediaItem.id),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 36, offset: const Offset(0, 18))],
                                  ),
                                  child: AlbumArt(audioId: audioId, size: artSize, borderRadius: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mediaItem.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall),
                                  const SizedBox(height: 4),
                                  Text(mediaItem.artist ?? 'Unknown Artist',
                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            _FavoriteButton(songId: songId),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _SeekBar(),
                        const SizedBox(height: 4),
                        const _TransportRow(),
                        const SizedBox(height: 18),
                        const _UtilityRow(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final String? songId;
  const _FavoriteButton({required this.songId});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final song = songId == null ? null : library.getById(songId!);
    final isFavorite = song?.isFavorite ?? false;
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      iconSize: 28,
      icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? scheme.primary : scheme.onSurfaceVariant),
      onPressed: songId == null ? null : () => context.read<LibraryProvider>().toggleFavorite(songId!),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar();

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<PositionData>(
      stream: player.positionDataStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final duration = data?.duration ?? Duration.zero;
        final position = data?.position ?? Duration.zero;
        final totalMs = duration.inMilliseconds;
        final liveValue = totalMs > 0 ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;
        final value = _dragValue ?? liveValue;
        final displayedPosition = _dragValue != null ? Duration(milliseconds: (_dragValue! * totalMs).round()) : position;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: value,
                onChanged: totalMs == 0 ? null : (v) => setState(() => _dragValue = v),
                onChangeEnd: totalMs == 0
                    ? null
                    : (v) {
                        player.seek(Duration(milliseconds: (v * totalMs).round()));
                        setState(() => _dragValue = null);
                      },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDurationFromDuration(displayedPosition), style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  Text(formatDurationFromDuration(duration), style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          iconSize: 24,
          icon: Icon(Icons.shuffle_rounded, color: player.shuffleEnabled ? scheme.primary : scheme.onSurfaceVariant),
          onPressed: player.toggleShuffle,
        ),
        IconButton(iconSize: 40, icon: Icon(Icons.skip_previous_rounded, color: scheme.onSurface), onPressed: player.previous),
        StreamBuilder<PlaybackState>(
          stream: player.playbackStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final procState = snapshot.data?.processingState;
            final loading = procState == AudioProcessingState.loading || procState == AudioProcessingState.buffering;
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
              child: loading
                  ? Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2.6, color: scheme.onPrimary))
                  : IconButton(
                      iconSize: 38,
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: scheme.onPrimary),
                      onPressed: player.togglePlayPause,
                    ),
            );
          },
        ),
        IconButton(iconSize: 40, icon: Icon(Icons.skip_next_rounded, color: scheme.onSurface), onPressed: player.next),
        IconButton(
          iconSize: 24,
          icon: Icon(
            player.repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: player.repeatMode == AudioServiceRepeatMode.none ? scheme.onSurfaceVariant : scheme.primary,
          ),
          onPressed: player.cycleRepeatMode,
        ),
      ],
    );
  }
}

class _UtilityRow extends StatelessWidget {
  const _UtilityRow();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _UtilityButton(icon: Icons.lyrics_outlined, label: 'Lyrics', onTap: () => _showLyricsPlaceholder(context)),
        _UtilityButton(
          icon: Icons.speed_rounded,
          label: _speedLabel(player.speed),
          highlighted: player.speed != 1.0,
          onTap: () => _showSpeedSheet(context),
        ),
        _UtilityButton(
          icon: player.hasSleepTimer ? Icons.bedtime_rounded : Icons.bedtime_outlined,
          label: 'Sleep',
          highlighted: player.hasSleepTimer,
          onTap: () => _showSleepTimerSheet(context),
        ),
        _UtilityButton(icon: Icons.queue_music_rounded, label: 'Queue', onTap: () => showQueueSheet(context)),
      ],
    );
  }

  String _speedLabel(double speed) => speed == speed.roundToDouble() ? '${speed.toInt()}x' : '${speed}x';
}

class _UtilityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _UtilityButton({required this.icon, required this.label, required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = highlighted ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

void _showLyricsPlaceholder(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lyrics_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Lyrics aren\'t available yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Zenova is fully offline and doesn\'t fetch lyrics from the internet. This spot is reserved for a future update.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSpeedSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Consumer<PlayerProvider>(
        builder: (context, player, _) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Align(alignment: Alignment.centerLeft, child: Text('Playback Speed', style: theme.textTheme.titleMedium)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.playbackSpeeds.map((speed) {
                    final selected = player.speed == speed;
                    return ChoiceChip(label: Text('${speed}x'), selected: selected, onSelected: (_) => player.setSpeed(speed));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

void _showSleepTimerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Consumer<PlayerProvider>(
        builder: (context, player, _) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(alignment: Alignment.centerLeft, child: Text('Sleep Timer', style: theme.textTheme.titleMedium)),
              ),
              if (player.hasSleepTimer)
                ListTile(
                  leading: Icon(Icons.bedtime_rounded, color: theme.colorScheme.primary),
                  title: const Text('Cancel timer'),
                  subtitle: Text('Stops in ${_formatRemaining(player.sleepTimerRemaining)}'),
                  onTap: () {
                    player.cancelSleepTimer();
                    Navigator.pop(ctx);
                  },
                ),
              ...AppConstants.sleepTimerOptions.map(
                (d) => ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text('${d.inMinutes} minutes'),
                  onTap: () {
                    player.startSleepTimer(d);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

String _formatRemaining(Duration? d) {
  if (d == null || d.isNegative) return '0m';
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  if (minutes <= 0) return '${seconds}s';
  return '${minutes}m ${seconds}s';
}
