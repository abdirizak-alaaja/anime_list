import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/recent_searches_store.dart';

/// Recent search terms, or a hint when there are none.
class RecentSearches extends StatelessWidget {
  const RecentSearches({super.key, required this.store, required this.onTap});

  final RecentSearchesStore store;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final terms = store.terms;
        if (terms.isEmpty) {
          return const EmptyView(
            icon: Icons.manage_search_rounded,
            title: 'Find your next anime',
            message: 'Search by title in English, Japanese or romaji.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Recent searches',
              actionLabel: 'Clear',
              onAction: store.clear,
            ),
            for (final term in terms)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                ),
                leading: const Icon(Icons.history_rounded),
                title: Text(term, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Remove "$term"',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => store.remove(term),
                ),
                onTap: () => onTap(term),
              ),
          ],
        );
      },
    );
  }
}
