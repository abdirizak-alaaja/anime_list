import 'dart:async';
import 'dart:convert';

import 'package:anime_list/core/errors/app_exception.dart';
import 'package:anime_list/core/network/jikan_http_client.dart';
import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<Duration> delays;
  late int calls;

  JikanHttpClient buildClient(MockClientHandler handler) {
    delays = [];
    calls = 0;
    return JikanHttpClient(
      httpClient: MockClient((request) {
        calls++;
        return handler(request);
      }),
      baseUrl: 'https://api.test/v4',
      rateLimiter: RateLimiter(limits: const [], delay: (_) async {}),
      delay: (d) async => delays.add(d),
    );
  }

  http.Response ok([Object body = const {'data': []}]) =>
      http.Response(jsonEncode(body), 200);

  test('builds URLs under the base path and drops null parameters', () {
    final client = buildClient((_) async => ok());
    final uri = client.buildUri('/anime/1', {'q': 'naruto', 'type': null});
    expect(uri.toString(), 'https://api.test/v4/anime/1?q=naruto');
  });

  test('caches successful responses', () async {
    final client = buildClient((_) async => ok());
    await client.get('anime');
    await client.get('anime');
    expect(calls, 1);

    await client.get('anime', forceRefresh: true);
    expect(calls, 2);
  });

  test('de-duplicates concurrent identical requests', () async {
    final completer = Completer<http.Response>();
    final client = buildClient((_) => completer.future);
    final first = client.get('top/anime');
    final second = client.get('top/anime');
    completer.complete(ok());
    await Future.wait([first, second]);
    expect(calls, 1);
  });

  test('retries transient server errors with backoff', () async {
    var attempt = 0;
    final client = buildClient(
      (_) async => ++attempt < 3 ? http.Response('{}', 504) : ok(),
    );
    await client.get('anime');
    expect(calls, 3);
    expect(delays, [const Duration(seconds: 1), const Duration(seconds: 2)]);
  });

  test('honors Retry-After on 429 and then gives up', () async {
    final client = buildClient(
      (_) async => http.Response('{}', 429, headers: {'retry-after': '3'}),
    );
    await expectLater(client.get('anime'), throwsA(isA<RateLimitException>()));
    expect(calls, 3);
    expect(delays, everyElement(const Duration(seconds: 3)));
  });

  test('maps status codes to app exceptions', () async {
    final notFound = buildClient((_) async => http.Response('{}', 404));
    await expectLater(
      notFound.get('anime/0'),
      throwsA(isA<NotFoundException>()),
    );
    expect(calls, 1, reason: '404 is not retried');

    final badRequest = buildClient((_) async => http.Response('{}', 400));
    await expectLater(badRequest.get('anime'), throwsA(isA<ServerException>()));
  });

  test(
    'maps connection failures to NetworkException after one retry',
    () async {
      final client = buildClient((_) async => throw http.ClientException('x'));
      await expectLater(client.get('anime'), throwsA(isA<NetworkException>()));
      expect(calls, 2);
    },
  );

  test('maps malformed JSON to ParseException', () async {
    final client = buildClient((_) async => http.Response('<html>', 200));
    await expectLater(client.get('anime'), throwsA(isA<ParseException>()));
  });

  test('failed requests are not cached', () async {
    var fail = true;
    final client = buildClient(
      (_) async => fail ? http.Response('{}', 404) : ok(),
    );
    await expectLater(client.get('anime'), throwsA(isA<AppException>()));
    fail = false;
    await client.get('anime');
    expect(calls, 2);
  });
}
