import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/library_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import 'folder_detail_screen.dart';

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final folders = library.folders;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: library.isScanning && folders.isEmpty
          ? const ShimmerList()
          : folders.isEmpty
              ? const EmptyState(icon: Icons.folder_outlined, title: 'No folders yet', message: 'Folders appear here once you\'ve imported some music.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(Icons.folder_rounded, color: theme.colorScheme.primary),
                      ),
                      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(pluralize(folder.songCount, 'song'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FolderDetailScreen(folderPath: folder.path))),
                    );
                  },
                ),
    );
  }
}
