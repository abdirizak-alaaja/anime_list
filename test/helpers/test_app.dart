import 'dart:convert';
import 'dart:io';

import 'package:anime_list/core/di/app_dependencies.dart';
import 'package:anime_list/core/di/app_scope.dart';
import 'package:anime_list/core/network/jikan_http_client.dart';
import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:anime_list/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Responds to a Jikan request path (e.g. `/v4/anime/1/full`) with a JSON
/// body, or `null` for a 404.
typedef FakeJikanHandler = Object? Function(Uri uri);

/// Dependencies backed by an in-memory store and a fake Jikan server.
AppDependencies testDependencies({
  FakeJikanHandler? handler,
  KeyValueStore? store,
}) {
  return AppDependencies(
    store: store ?? InMemoryKeyValueStore(),
    httpClient: JikanHttpClient(
      httpClient: MockClient((request) async {
        final body = (handler ?? (_) => {'data': []})(request.url);
        if (body == null) return http.Response('{}', 404);
        return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
      }),
      rateLimiter: RateLimiter(limits: const []),
      delay: (_) async {},
    ),
  );
}

/// Wraps [child] in the app theme and dependency scope.
Widget testApp(AppDependencies deps, Widget child) {
  return AppScope(
    dependencies: deps,
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

Object? fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());
