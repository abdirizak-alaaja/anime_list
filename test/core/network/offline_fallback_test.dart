import 'dart:convert';

import 'package:anime_list/core/errors/app_exception.dart';
import 'package:anime_list/core/network/api_health.dart';
import 'package:anime_list/core/network/jikan_http_client.dart';
import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:anime_list/core/network/saved_response_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late InMemorySavedResponses saved;
  late ApiHealth health;
  late http.Response Function() respond;

  JikanHttpClient buildClient() => JikanHttpClient(
    httpClient: MockClient((_) async => respond()),
    baseUrl: 'https://api.test/v4',
    rateLimiter: RateLimiter(limits: const []),
    savedResponses: saved,
    health: health,
    delay: (_) async {},
  );

  setUp(() {
    saved = InMemorySavedResponses();
    health = ApiHealth();
  });

  test('saves successful responses and reports online', () async {
    respond = () => http.Response(jsonEncode({'data': 1}), 200);
    await buildClient().get('anime/1');
    await Future<void>.delayed(Duration.zero);
    expect(saved.entries.values.single, {'data': 1});
    expect(health.state, ApiHealthState.online);
  });

  test('serves saved data when offline', () async {
    respond = () => http.Response(jsonEncode({'data': 'fresh'}), 200);
    await buildClient().get('anime/1');
    await Future<void>.delayed(Duration.zero);

    respond = () => throw http.ClientException('offline');
    final result = await buildClient().get('anime/1');
    expect(result, {'data': 'fresh'});
    expect(health.state, ApiHealthState.offline);
  });

  test('serves saved data when Jikan is down', () async {
    saved.entries['https://api.test/v4/top/anime'] = {'data': 'old'};
    respond = () => http.Response('{}', 504);
    expect(await buildClient().get('top/anime'), {'data': 'old'});
    expect(health.state, ApiHealthState.degraded);
  });

  test('without saved data, the original error surfaces', () async {
    respond = () => throw http.ClientException('offline');
    await expectLater(
      buildClient().get('anime/2'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('a success clears the offline state', () async {
    respond = () => throw http.ClientException('offline');
    final client = buildClient();
    await expectLater(client.get('a'), throwsA(isA<NetworkException>()));
    expect(health.isOnline, isFalse);

    respond = () => http.Response('{}', 200);
    await client.get('b');
    expect(health.isOnline, isTrue);
  });

  test('not-found is never masked by saved data', () async {
    saved.entries['https://api.test/v4/anime/3'] = {'data': 'old'};
    respond = () => http.Response('{}', 404);
    await expectLater(
      buildClient().get('anime/3'),
      throwsA(isA<NotFoundException>()),
    );
  });
}
