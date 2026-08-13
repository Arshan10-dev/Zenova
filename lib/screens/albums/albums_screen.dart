import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grid_cards.dart';
import '../../widgets/loading_shimmer.dart';
import 'album_detail_screen.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final albums = library.albums;

    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: library.isScanning && albums.isEmpty
          ? const ShimmerGrid()
          : albums.isEmpty
              ? const EmptyState(icon: Icons.album_outlined, title: 'No albums yet', message: 'Albums appear here once you\'ve imported some music.')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return AlbumGridCard(
                      album: album,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumDetailScreen(albumKey: album.key))),
                    );
                  },
                ),
    );
  }
}
