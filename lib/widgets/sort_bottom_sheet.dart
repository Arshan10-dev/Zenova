import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sort_options.dart';
import '../providers/library_provider.dart';

Future<void> showSortBottomSheet(BuildContext context) {
  return showModalBottomSheet(context: context, builder: (_) => const _SortSheetContent());
}

class _SortSheetContent extends StatelessWidget {
  const _SortSheetContent();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sort by', style: theme.textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => context.read<LibraryProvider>().toggleSortDirection(),
                  icon: Icon(library.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18),
                  label: Text(library.sortAscending ? 'Ascending' : 'Descending'),
                ),
              ],
            ),
          ),
          ...SongSortBy.values.map(
            (option) => RadioListTile<SongSortBy>(
              value: option,
              groupValue: library.sortBy,
              title: Text(option.label),
              onChanged: (value) {
                if (value != null) context.read<LibraryProvider>().setSortBy(value);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
