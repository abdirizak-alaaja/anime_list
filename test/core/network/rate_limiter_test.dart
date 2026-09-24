import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spaces requests to stay within every limit', () async {
    var now = DateTime(2024);
    final sent = <DateTime>[];
    final limiter = RateLimiter(
      limits: const [
        RateLimit(3, Duration(seconds: 1)),
        RateLimit(5, Duration(minutes: 1)),
      ],
      now: () => now,
      delay: (d) async => now = now.add(d),
    );

    for (var i = 0; i < 7; i++) {
      await limiter.acquire();
      sent.add(now);
    }

    final offsets = [for (final t in sent) t.difference(DateTime(2024))];
    expect(offsets.take(3), everyElement(Duration.zero));
    expect(offsets[3], const Duration(seconds: 1));
    expect(offsets[4], const Duration(seconds: 1));
    // The per-minute limit (5) kicks in for the 6th request.
    expect(offsets[5], const Duration(minutes: 1));
    expect(offsets[6], const Duration(minutes: 1));
  });

  test('serves concurrent callers in order', () async {
    var now = DateTime(2024);
    final limiter = RateLimiter(
      limits: const [RateLimit(1, Duration(seconds: 1))],
      now: () => now,
      delay: (d) async => now = now.add(d),
    );
    final order = <int>[];
    await Future.wait([
      for (var i = 0; i < 3; i++) limiter.acquire().then((_) => order.add(i)),
    ]);
    expect(order, [0, 1, 2]);
    expect(now, DateTime(2024).add(const Duration(seconds: 2)));
  });
}
