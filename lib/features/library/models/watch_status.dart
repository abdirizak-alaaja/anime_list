import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// MyAnimeList-style list status.
enum WatchStatus {
  watching('watching', 'Watching', Icons.play_circle_outline_rounded),
  completed('completed', 'Completed', Icons.check_circle_outline_rounded),
  onHold('on_hold', 'On Hold', Icons.pause_circle_outline_rounded),
  dropped('dropped', 'Dropped', Icons.cancel_outlined),
  planToWatch('plan_to_watch', 'Plan to Watch', Icons.schedule_rounded);

  const WatchStatus(this.storageKey, this.label, this.icon);

  /// Stable value persisted to disk; never change it.
  final String storageKey;
  final String label;
  final IconData icon;

  /// MyAnimeList's status color, adjusted for contrast in dark mode.
  Color colorFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      watching => AppColors.watching,
      completed => dark ? AppColors.completedOnDark : AppColors.completed,
      onHold => AppColors.onHold,
      dropped => dark ? AppColors.droppedOnDark : AppColors.dropped,
      planToWatch =>
        dark ? AppColors.planToWatch : AppColors.planToWatchOnLight,
    };
  }

  static WatchStatus? fromStorageKey(String? key) {
    for (final status in values) {
      if (status.storageKey == key) return status;
    }
    return null;
  }
}
