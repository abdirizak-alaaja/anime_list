import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

/// A centered icon, title, message and optional action.
///
/// Base for [EmptyView] and [ErrorView].
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Uses a smaller layout suitable for inline sections.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? Insets.lg : Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 32 : 56,
              color: scheme.primary.withValues(alpha: 0.8),
            ),
            SizedBox(height: compact ? Insets.sm : Insets.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: Insets.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? Insets.sm : Insets.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a list or screen has nothing to display.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: icon,
    title: title,
    message: message,
    action: action,
    compact: compact,
  );
}

/// Shown when a load fails. Maps [AppException] types to friendly visuals.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final AppException error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, title) = switch (error) {
      NetworkException() => (Icons.wifi_off_rounded, 'No connection'),
      RequestTimeoutException() => (Icons.timer_off_outlined, 'Timed out'),
      RateLimitException() => (Icons.hourglass_top_rounded, 'Slow down'),
      NotFoundException() => (Icons.search_off_rounded, 'Not found'),
      _ => (Icons.cloud_off_rounded, 'Something went wrong'),
    };

    return MessageView(
      icon: icon,
      title: title,
      message: error.message,
      compact: compact,
      action: onRetry != null && error.isRetryable
          ? FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            )
          : null,
    );
  }
}
