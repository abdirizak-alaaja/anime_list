import 'dart:convert';
import 'dart:io';

import 'package:anime_list/core/errors/app_exception.dart';
import 'package:anime_list/core/network/jikan_api.dart';
import 'package:anime_list/core/network/jikan_http_client.dart';
import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:anime_list/shared/models/anime_enums.dart';
import 'package:anime_list/shared/models/anime_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<Uri> requests;

  JikanApi buildApi(Object Function(Uri uri) respond) {
    requests = [];
    return JikanApi(
      JikanHttpClient(
        httpClient: MockClient((request) async {
          requests.add(request.url);
          final body = respond(request.url);
          return body is http.Response
              ? body
              : http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
        }),
        baseUrl: 'https://api.test/v4',
        rateLimiter: RateLimiter(limits: const []),
        delay: (_) async {},
      ),
    );
  }

  test('parses a full anime response', () async {
    final fixture = jsonDecode(
      File('test/fixtures/anime_full.json').readAsStringSync(),
    );
    final api = buildApi((_) => fixture);

    final anime = await api.getAnimeFull(52991);

    expect(requests.single.path, '/v4/anime/52991/full');
    expect(anime.title, 'Sousou no Frieren');
    expect(anime.titleJapanese, '葬送のフリーレン');
    expect(anime.episodes, 28);
    expect(anime.score, 9.26);
    expect(anime.season, AnimeSeason.fall);
    expect(anime.year, 2023);
    expect(anime.studios.map((s) => s.name), contains('Madhouse'));
    expect(anime.genres, isNotEmpty);
    expect(anime.largeImageUrl, startsWith('https://'));
    expect(anime.synopsis, isNot(contains('MAL Rewrite')));
  });

  test('tolerates missing and null fields', () async {
    final api = buildApi(
      (_) => {
        'data': {
          'mal_id': 1,
          'title': 'Minimal',
          'episodes': null,
          'score': null,
          'images': null,
          'genres': null,
          'aired': {'from': null, 'string': 'Not available'},
          'duration': 'Unknown',
        },
      },
    );

    final anime = await api.getAnime(1);
    expect(anime.title, 'Minimal');
    expect(anime.episodes, isNull);
    expect(anime.imageUrl, isNull);
    expect(anime.genres, isEmpty);
    expect(anime.airedLabel, isNull);
    expect(anime.duration, isNull);
  });

  test('missing data object is reported as not found', () async {
    final api = buildApi((_) => {'data': null});
    await expectLater(api.getAnime(1), throwsA(isA<NotFoundException>()));
  });

  test('parses paginated lists and skips invalid items', () async {
    final api = buildApi(
      (_) => {
        'pagination': {
          'current_page': 2,
          'has_next_page': true,
          'last_visible_page': 9,
          'items': {'total': 200},
        },
        'data': [
          {'mal_id': 1, 'title': 'One'},
          {'title': 'No id'},
          {'mal_id': 3, 'title': 'Three'},
        ],
      },
    );

    final page = await api.getTopAnime(filter: TopAnimeFilter.airing, page: 2);

    expect(page.items.map((a) => a.malId), [1, 3]);
    expect(page.currentPage, 2);
    expect(page.hasNextPage, isTrue);
    expect(page.totalItems, 200);
    expect(requests.single.queryParameters, containsPair('filter', 'airing'));
    expect(requests.single.queryParameters, containsPair('page', '2'));
  });

  test('empty responses produce empty pages', () async {
    final api = buildApi((_) => <String, dynamic>{});
    final page = await api.getCurrentSeason();
    expect(page.items, isEmpty);
    expect(page.hasNextPage, isFalse);
  });

  test('search sends filters and sorting as query parameters', () async {
    final api = buildApi((_) => {'data': []});
    await api.searchAnime(
      AnimeQuery(
        text: ' frieren ',
        genreIds: const [1, 2],
        type: AnimeType.tv,
        status: AnimeStatus.complete,
        rating: AnimeRating.pg13,
        minScore: 7.5,
        startDate: DateTime(2023, 1, 1),
        orderBy: AnimeOrderBy.score,
      ),
    );

    expect(requests.single.queryParameters, {
      'q': 'frieren',
      'genres': '1,2',
      'type': 'tv',
      'status': 'complete',
      'rating': 'pg13',
      'min_score': '7.5',
      'start_date': '2023-01-01',
      'order_by': 'score',
      'sort': 'desc',
      'sfw': 'true',
      'page': '1',
      'limit': '${JikanApi.pageSize}',
    });
  });

  test('genres exclude explicit entries and are sorted', () async {
    final api = buildApi(
      (_) => {
        'data': [
          {'mal_id': 2, 'name': 'Adventure'},
          {'mal_id': 12, 'name': 'Hentai'},
          {'mal_id': 1, 'name': 'Action'},
        ],
      },
    );
    final genres = await api.getAnimeGenres();
    expect(genres.map((g) => g.name), ['Action', 'Adventure']);
  });

  test('characters are ordered main cast first', () async {
    final api = buildApi(
      (_) => {
        'data': [
          {
            'character': {'mal_id': 1, 'name': 'Side'},
            'role': 'Supporting',
            'favorites': 999,
          },
          {
            'character': {'mal_id': 2, 'name': 'Lead'},
            'role': 'Main',
            'favorites': 5,
            'voice_actors': [
              {
                'person': {'mal_id': 9, 'name': 'Tanezaki, Atsumi'},
                'language': 'Japanese',
              },
            ],
          },
        ],
      },
    );
    final characters = await api.getAnimeCharacters(1);
    expect(characters.map((c) => c.name), ['Lead', 'Side']);
    expect(characters.first.voiceActorName, 'Tanezaki, Atsumi');
  });
}
