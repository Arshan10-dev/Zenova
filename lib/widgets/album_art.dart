import 'package:flutter/material.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart' as oaq;

import '../core/constants/app_colors.dart';

class AlbumArt extends StatelessWidget {
  final int? audioId;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  const AlbumArt({
    super.key,
    required this.audioId,
    this.size = 56,
    this.borderRadius = 12,
    this.fallbackIcon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final id = audioId;

    if (id == null) {
      return ClipRRect(borderRadius: radius, child: _fallback());
    }

    return ClipRRect(
      borderRadius: radius,
      child: oaq.QueryArtworkWidget(
        id: id,
        type: oaq.ArtworkType.AUDIO,
        artworkFit: BoxFit.cover,
        artworkWidth: size,
        artworkHeight: size,
        artworkBorder: BorderRadius.zero,
        keepOldArtworkWidget: true,
        nullArtworkWidget: _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.fallbackArtGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, color: Colors.white.withValues(alpha: 0.65), size: size * 0.4),
      ),
    );
  }
}
