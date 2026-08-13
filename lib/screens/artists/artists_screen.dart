import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grid_cards.dart';
import '../../widgets/loading_shimmer.dart';
import 'artist_detail_screen.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final artists = library.artists;

    return Scaffold(
      appBar: AppBar(title: const Text('Artists')),
      body: library.isScanning && artists.isEmpty
          ? const ShimmerGrid()
          : artists.isEmpty
              ? const EmptyState(icon: Icons.person_outline_rounded, title: 'No artists yet', message: 'Artists appear here once you\'ve imported some music.')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return ArtistGridCard(
                      artist: artist,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArtistDetailScreen(artistName: artist.name))),
                    );
                  },
                ),
    );
  }
}
