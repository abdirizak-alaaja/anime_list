/// App-wide configuration values.
abstract final class AppConstants {
  static const appName = 'AniShelf';

  static const publicJikanBaseUrl = 'https://api.jikan.moe/v4';

  /// Jikan REST API base URL. Override at build time to use a self-hosted
  /// instance, e.g. `--dart-define=JIKAN_BASE_URL=http://localhost:8080/v4`
  /// (use `http://10.0.2.2:8080/v4` from the Android emulator).
  static const jikanBaseUrl = String.fromEnvironment(
    'JIKAN_BASE_URL',
    defaultValue: publicJikanBaseUrl,
  );

  /// Whether requests go to the public, rate-limited api.jikan.moe.
  static bool get usesPublicJikan =>
      Uri.parse(jikanBaseUrl).host == Uri.parse(publicJikanBaseUrl).host;

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
