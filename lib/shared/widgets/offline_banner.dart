import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_health.dart';

/// Slim notice shown while Jikan can't be reached. Hides itself as soon as
/// any request succeeds again.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.health});

  final ApiHealth health;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        final message = switch (health.state) {
          ApiHealthState.online => null,
          ApiHealthState.offline =>
            "You're offline. Showing saved data; My List and Favorites "
                'work as usual.',
          ApiHealthState.degraded =>
            'MyAnimeList is having trouble. Showing saved data where '
                'available.',
        };

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: message == null
              ? const SizedBox(width: double.infinity)
              : _Banner(
                  message: message,
                  icon: health.state == ApiHealthState.offline
                      ? Icons.wifi_off_rounded
                      : Icons.cloud_off_rounded,
                ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSecondaryContainer),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
