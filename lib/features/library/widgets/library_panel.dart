import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../shared/models/anime.dart';
import 'episode_stepper.dart';
import 'status_picker.dart';

/// "Add to list" button, or status + episode progress controls once the
/// anime is in the library.
class LibraryPanel extends StatelessWidget {
  const LibraryPanel({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;

    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final entry = library.entryFor(anime.malId);

        if (entry == null) {
          return FilledButton.icon(
            onPressed: () async {
              final status = await showStatusPicker(context);
              if (status != null) await library.add(anime, status: status);
            },
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text('Add to My List'),
          );
        }

        final theme = Theme.of(context);
        final progress = entry.progress;
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.sm,
              Insets.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      status: entry.status,
                      onTap: () async {
                        final status = await showStatusPicker(
                          context,
                          current: entry.status,
                        );
                        if (status != null) {
                          await library.setStatus(anime.malId, status);
                        }
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove from My List',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmRemove(context),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                Row(
                  children: [
                    Text('Episodes', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    EpisodeStepper(
                      watched: entry.episodesWatched,
                      total: entry.totalEpisodes,
                      onChanged: (value) =>
                          library.setEpisodesWatched(anime.malId, value),
                    ),
                  ],
                ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.sm),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: entry.status.colorFor(theme.brightness),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final library = AppScope.of(context).library;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from My List?'),
        content: Text(
          'Your status and progress for "${anime.title}" will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) await library.remove(anime.malId);
  }
}
