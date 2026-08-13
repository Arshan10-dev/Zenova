import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/song_actions_sheet.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/sort_bottom_sheet.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final songs = library.filteredSortedSongs;

    return Scaffold(
      appBar: library.isSelectionMode ? _buildSelectionAppBar(context, library) : _buildNormalAppBar(context, library),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search songs, artists, albums',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainer),
              trailing: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<LibraryProvider>().setSearchQuery('');
                          },
                        ),
                ),
              ],
              onChanged: (value) => context.read<LibraryProvider>().setSearchQuery(value),
            ),
          ),
          Expanded(child: _buildList(context, library, songs)),
        ],
      ),
      floatingActionButton: library.isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showImportSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Songs'),
            ),
    );
  }

  Widget _buildList(BuildContext context, LibraryProvider library, List<SongModel> songs) {
    if (library.isScanning && songs.isEmpty) return const ShimmerList();

    if (songs.isEmpty) {
      final searching = library.searchQuery.trim().isNotEmpty;
      return EmptyState(
        icon: searching ? Icons.search_off_rounded : Icons.library_music_outlined,
        title: searching ? 'No results' : 'No songs yet',
        message: searching ? 'Nothing matches "${library.searchQuery}".' : 'Scan your device or tap "Add Songs" to import music.',
        actionLabel: searching ? null : 'Scan for Music',
        onAction: searching ? null : () => context.read<LibraryProvider>().scanLibrary(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 160, top: 4),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final selected = library.selectedIds.contains(song.id);
        return SongTile(
          song: song,
          selectionMode: library.isSelectionMode,
          selected: selected,
          onTap: () {
            if (library.isSelectionMode) {
              context.read<LibraryProvider>().toggleSelection(song.id);
            } else {
              context.read<PlayerProvider>().playFromContext(song, songs);
            }
          },
          onLongPress: () {
            if (!library.isSelectionMode) context.read<LibraryProvider>().enterSelectionMode(song.id);
          },
          onToggleFavorite: () => context.read<LibraryProvider>().toggleFavorite(song.id),
          onMore: () => showSongOptionsSheet(context, song),
        );
      },
    );
  }

  AppBar _buildNormalAppBar(BuildContext context, LibraryProvider library) {
    return AppBar(
      title: const Text('Songs'),
      actions: [
        IconButton(tooltip: 'Sort', icon: const Icon(Icons.sort_rounded), onPressed: () => showSortBottomSheet(context)),
        IconButton(
          tooltip: 'Rescan library',
          icon: library.isScanning
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
          onPressed: library.isScanning ? null : () => context.read<LibraryProvider>().scanLibrary(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context, LibraryProvider library) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.read<LibraryProvider>().clearSelection()),
      title: Text('${library.selectedIds.length} selected'),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all_rounded),
          onPressed: () => context.read<LibraryProvider>().selectAll(library.filteredSortedSongs),
        ),
        IconButton(
          tooltip: 'Add to playlist',
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: () => showAddToPlaylistSheet(context, library.selectedIds.toList()),
        ),
        IconButton(
          tooltip: 'Remove from library',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _confirmBulkDelete(context, library),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showImportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Add Songs', style: Theme.of(sheetContext).textTheme.titleMedium)),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: const Text('Choose Files'),
              subtitle: const Text('Pick one or more songs'),
              onTap: () {
                Navigator.pop(sheetContext);
                _runImport(context, context.read<LibraryProvider>().importFiles());
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Choose a Folder'),
              subtitle: const Text('Import every supported file inside'),
              onTap: () {
                Navigator.pop(sheetContext);
                _runImport(context, context.read<LibraryProvider>().importFolder());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _runImport(BuildContext context, Future<void> importFuture) async {
    await importFuture;
    if (!mounted) return;
    final library = context.read<LibraryProvider>();
    if (library.lastSkippedImports.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${library.lastSkippedImports.length} file(s) couldn\'t be imported (unsupported or corrupted).')));
    } else if (library.lastError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(library.lastError!)));
    }
  }

  void _confirmBulkDelete(BuildContext context, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from Library?'),
        content: Text('${library.selectedIds.length} song(s) will be removed from Zenova. This won\'t delete the files from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final ids = List<String>.from(library.selectedIds);
              context.read<LibraryProvider>().removeFromLibrary(ids);
              Navigator.pop(dialogContext);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
