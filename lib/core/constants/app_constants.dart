/// App-wide configuration values.
abstract final class AppConstants {
  static const appName = 'AniShelf';

  /// Jikan REST API base URL. Can be overridden at build time with
  /// `--dart-define=JIKAN_BASE_URL=...` (e.g. for a self-hosted mirror).
  static const jikanBaseUrl = String.fromEnvironment(
    'JIKAN_BASE_URL',
    defaultValue: 'https://api.jikan.moe/v4',
  );

  /// Width at which the layout switches from bottom navigation to a rail.
  static const wideLayoutBreakpoint = 840.0;
}

/// Spacing scale used across the UI.
abstract final class Insets {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
