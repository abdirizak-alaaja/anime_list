import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../utils/json.dart';
import 'rate_limiter.dart';
import 'response_cache.dart';

/// Low-level HTTP access to the Jikan API.
///
/// Every request goes through, in order:
/// 1. the response cache (unless [get]'s `forceRefresh` is set),
/// 2. in-flight de-duplication, so identical concurrent requests share one
///    network call,
/// 3. the [RateLimiter],
/// 4. retries with exponential backoff for rate limiting (429), transient
///    server errors (5xx, which Jikan returns when MyAnimeList is slow), and
///    one retry for timeouts and connection failures.
///
/// Failures always surface as [AppException]s.
class JikanHttpClient {
  JikanHttpClient({
    http.Client? httpClient,
    String baseUrl = AppConstants.jikanBaseUrl,
    RateLimiter? rateLimiter,
    ResponseCache? cache,
    this.timeout = const Duration(seconds: 15),
    this.maxServerRetries = 2,
    this.maxNetworkRetries = 1,
    Future<void> Function(Duration)? delay,
  }) : _http = httpClient ?? http.Client(),
       _baseUri = Uri.parse(baseUrl),
       _rateLimiter =
           rateLimiter ??
           RateLimiter(
             limits: AppConstants.usesPublicJikan
                 ? RateLimiter.publicJikanLimits
                 : RateLimiter.selfHostedLimits,
           ),
       _cache = cache ?? MemoryResponseCache(),
       _delay = delay ?? Future<void>.delayed;

  static const defaultCacheTtl = Duration(minutes: 10);

  final http.Client _http;
  final Uri _baseUri;
  final RateLimiter _rateLimiter;
  final ResponseCache _cache;
  final Future<void> Function(Duration) _delay;

  final Duration timeout;
  final int maxServerRetries;
  final int maxNetworkRetries;

  final Map<String, Future<Json>> _inFlight = {};

  /// Fetches `GET {baseUrl}/{path}?{query}` as a JSON object.
  ///
  /// `null` query values are omitted.
  Future<Json> get(
    String path, {
    Map<String, Object?> query = const {},
    Duration cacheTtl = defaultCacheTtl,
    bool forceRefresh = false,
  }) {
    final uri = buildUri(path, query);
    final key = uri.toString();

    if (!forceRefresh) {
      final cached = _cache.get(key);
      if (cached != null) return Future.value(cached);
    }

    return _inFlight[key] ??= _fetch(uri, cacheTtl).whenComplete(() {
      // Block body on purpose: returning the removed future from this
      // callback would make the request wait on itself.
      _inFlight.remove(key);
    });
  }

  Uri buildUri(String path, [Map<String, Object?> query = const {}]) {
    final params = <String, String>{
      for (final MapEntry(:key, :value) in query.entries)
        if (value != null && value.toString().isNotEmpty) key: '$value',
    };
    final segments = [
      ..._baseUri.pathSegments.where((s) => s.isNotEmpty),
      ...path.split('/').where((s) => s.isNotEmpty),
    ];
    return _baseUri.replace(
      pathSegments: segments,
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<Json> _fetch(Uri uri, Duration cacheTtl) async {
    var serverAttempts = 0;
    var networkAttempts = 0;

    while (true) {
      await _rateLimiter.acquire();

      final http.Response response;
      try {
        response = await _http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(timeout);
      } on TimeoutException {
        if (networkAttempts++ < maxNetworkRetries) continue;
        throw const RequestTimeoutException();
      } on http.ClientException {
        if (networkAttempts++ < maxNetworkRetries) {
          await _delay(const Duration(milliseconds: 500));
          continue;
        }
        throw const NetworkException();
      }

      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        final json = _decode(response.bodyBytes);
        _cache.put(uri.toString(), json, cacheTtl);
        return json;
      }

      final retryable = status == 429 || _isTransientServerError(status);
      if (retryable && serverAttempts < maxServerRetries) {
        await _delay(_backoff(serverAttempts, response.headers['retry-after']));
        serverAttempts++;
        continue;
      }

      throw _exceptionFor(status);
    }
  }

  static bool _isTransientServerError(int status) =>
      status == 500 || status == 502 || status == 503 || status == 504;

  static Duration _backoff(int attempt, String? retryAfter) {
    final requested = int.tryParse(retryAfter ?? '');
    if (requested != null && requested > 0) {
      return Duration(seconds: math.min(requested, 10));
    }
    // 1s, 2s, 4s, ...
    return Duration(milliseconds: 1000 * math.pow(2, attempt).toInt());
  }

  static AppException _exceptionFor(int status) => switch (status) {
    404 => const NotFoundException(),
    429 => const RateLimitException(),
    _ => ServerException(statusCode: status),
  };

  /// Always decodes as UTF-8: Jikan doesn't declare a charset, and the
  /// `http` package would otherwise fall back to Latin-1 and garble
  /// Japanese titles.
  static Json _decode(List<int> bytes) {
    try {
      final decoded = asJson(jsonDecode(utf8.decode(bytes)));
      if (decoded == null) throw const ParseException();
      return decoded;
    } on FormatException {
      throw const ParseException();
    }
  }

  void close() => _http.close();
}
