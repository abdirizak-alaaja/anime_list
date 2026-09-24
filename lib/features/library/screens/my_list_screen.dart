import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/theme_mode_button.dart';
import '../models/library_entry.dart';
import '../models/library_sort.dart';
import '../models/watch_status.dart';
import '../repositories/library_repository.dart';
import '../widgets/library_list_tile.dart';
import '../widgets/status_picker.dart';

/// My List tab: the library grouped by status. Works fully offline.
class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  LibrarySort _sort = LibrarySort.recentlyUpdated;

  /// `null` is the "All" tab.
  static const List<WatchStatus?> _tabs = [null, ...WatchStatus.values];

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;

    return DefaultTabController(
      length: _tabs.length,
      child: ListenableBuilder(
        listenable: library,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('My List'),
            actions: [
              PopupMenuButton<LibrarySort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort_rounded),
                initialValue: _sort,
                onSelected: (sort) => setState(() => _sort = sort),
                itemBuilder: (context) => [
                  for (final sort in LibrarySort.values)
                    CheckedPopupMenuItem(
                      value: sort,
                      checked: sort == _sort,
                      child: Text(sort.label),
                    ),
                ],
              ),
              const ThemeModeButton(),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final status in _tabs)
                  Tab(
                    text: status == null
                        ? 'All (${library.entries.length})'
                        : '${status.label} (${library.countFor(status)})',
                  ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              for (final status in _tabs)
                _StatusList(
                  library: library,
                  entries: _sort.apply([
                    for (final e in library.entries)
                      if (status == null || e.status == status) e,
                  ]),
                  status: status,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({
    required this.library,
    required this.entries,
    required this.status,
  });

  final LibraryRepository library;
  final List<LibraryEntry> entries;
  final WatchStatus? status;

  Future<void> _changeStatus(BuildContext context, LibraryEntry entry) async {
    final status = await showStatusPicker(context, current: entry.status);
    if (status != null) await library.setStatus(entry.malId, status);
  }

  Future<void> _remove(BuildContext context, LibraryEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    await library.remove(entry.malId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${entry.anime.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => library.restore(entry),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyView(
        icon: status?.icon ?? Icons.video_library_outlined,
        title: status == null
            ? 'Your list is empty'
            : 'Nothing in ${status!.label}',
        message: status == null
            ? 'Add anime from Discover or Search to track what you watch.'
            : null,
      );
    }

    return ListView.separated(
      // Keeps each tab's scroll position when switching tabs.
      key: PageStorageKey('my-list-${status?.name ?? 'all'}'),
      padding: const EdgeInsets.all(Insets.lg),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: ValueKey(entry.malId),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          onDismissed: (_) => _remove(context, entry),
          child: LibraryListTile(
            entry: entry,
            onTap: () => AppRouter.openAnime(
              context,
              malId: entry.malId,
              preview: entry.anime.toAnime(),
            ),
            onStatusTap: () => _changeStatus(context, entry),
            onEpisodesChanged: (value) =>
                library.setEpisodesWatched(entry.malId, value),
          ),
        );
      },
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
    );
  }
}
