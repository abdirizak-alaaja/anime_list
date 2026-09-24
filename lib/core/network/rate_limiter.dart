import 'dart:collection';

/// At most [count] requests per [window].
class RateLimit {
  const RateLimit(this.count, this.window);

  final int count;
  final Duration window;
}

/// Serializes callers so that no configured [RateLimit] is exceeded.
///
/// See [publicJikanLimits] and [selfHostedLimits].
class RateLimiter {
  RateLimiter({
    this.limits = publicJikanLimits,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
  }) : _now = now ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed,
       _longestWindow = limits
           .map((l) => l.window)
           .fold(Duration.zero, (a, b) => a > b ? a : b);

  /// api.jikan.moe: 3 requests/second and 60/minute, with headroom.
  static const publicJikanLimits = [
    RateLimit(3, Duration(milliseconds: 1200)),
    RateLimit(55, Duration(minutes: 1)),
  ];

  /// A self-hosted Jikan has no API rate limit, but it scrapes MyAnimeList
  /// on cache misses, and MyAnimeList may block IPs that request too fast.
  static const selfHostedLimits = [RateLimit(10, Duration(seconds: 1))];

  final List<RateLimit> limits;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;
  final Duration _longestWindow;

  final Queue<DateTime> _history = Queue();
  Future<void> _tail = Future.value();

  /// Completes when the caller may send a request.
  ///
  /// Callers are served in FIFO order.
  Future<void> acquire() {
    final turn = _tail.then((_) => _waitForSlot());
    _tail = turn;
    return turn;
  }

  Future<void> _waitForSlot() async {
    while (true) {
      final now = _now();
      _prune(now);

      final wait = _requiredWait(now);
      if (wait <= Duration.zero) {
        _history.addLast(now);
        return;
      }
      await _delay(wait);
    }
  }

  Duration _requiredWait(DateTime now) {
    var wait = Duration.zero;
    final history = _history.toList(growable: false);
    for (final limit in limits) {
      final windowStart = now.subtract(limit.window);
      final recent = history.where((t) => t.isAfter(windowStart)).toList();
      if (recent.length < limit.count) continue;
      // The slot frees up once the oldest of the last `count` requests
      // leaves the window.
      final oldest = recent[recent.length - limit.count];
      final limitWait = oldest.add(limit.window).difference(now);
      if (limitWait > wait) wait = limitWait;
    }
    return wait;
  }

  void _prune(DateTime now) {
    final cutoff = now.subtract(_longestWindow);
    while (_history.isNotEmpty && !_history.first.isAfter(cutoff)) {
      _history.removeFirst();
    }
  }
}
