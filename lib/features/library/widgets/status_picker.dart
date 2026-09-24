import 'package:flutter/material.dart';

import '../models/watch_status.dart';

/// Bottom sheet for choosing a [WatchStatus]. Returns `null` if dismissed.
Future<WatchStatus?> showStatusPicker(
  BuildContext context, {
  WatchStatus? current,
}) {
  return showModalBottomSheet<WatchStatus>(
    context: context,
    useSafeArea: true,
    // Size to content, scrolling on short screens or with large text.
    isScrollControlled: true,
    builder: (context) {
      final brightness = Theme.of(context).brightness;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  current == null ? 'Add to My List' : 'Change status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final status in WatchStatus.values)
                ListTile(
                  leading: Icon(
                    status.icon,
                    color: status.colorFor(brightness),
                  ),
                  title: Text(status.label),
                  trailing: status == current
                      ? const Icon(Icons.check_rounded)
                      : null,
                  selected: status == current,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Small colored pill showing a status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.onTap});

  final WatchStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = status.colorFor(Theme.of(context).brightness);
    return Material(
      color: color.withValues(alpha: 0.16),
      shape: StadiumBorder(side: BorderSide(color: color)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                status.label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down_rounded, size: 18, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
