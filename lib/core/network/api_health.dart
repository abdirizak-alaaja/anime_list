import 'package:flutter/foundation.dart';

enum ApiHealthState {
  online,

  /// The device couldn't reach the server.
  offline,

  /// The server answered with errors (Jikan or MyAnimeList is down, or
  /// we're being rate limited).
  degraded,
}

/// Tracks whether recent API requests are succeeding, for the offline
/// banner. Updated by the HTTP client; any success resets it to online.
class ApiHealth extends ChangeNotifier {
  ApiHealthState _state = ApiHealthState.online;

  ApiHealthState get state => _state;

  bool get isOnline => _state == ApiHealthState.online;

  void reportSuccess() => _set(ApiHealthState.online);

  void reportOffline() => _set(ApiHealthState.offline);

  void reportDegraded() => _set(ApiHealthState.degraded);

  void _set(ApiHealthState state) {
    if (state == _state) return;
    _state = state;
    notifyListeners();
  }
}
