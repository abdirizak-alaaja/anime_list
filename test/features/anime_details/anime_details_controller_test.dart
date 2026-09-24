import 'package:anime_list/core/errors/app_exception.dart';
import 'package:anime_list/core/state/async_state.dart';
import 'package:anime_list/features/anime_details/controllers/anime_details_controller.dart';
import 'package:anime_list/features/anime_details/repositories/anime_details_repository.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:anime_list/shared/models/anime_character.dart';
import 'package:anime_list/shared/models/anime_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements AnimeDetailsRepository {
  bool failDetails = false;
  bool failCharacters = false;
  final calls = <String>[];

  @override
  Future<Anime> details(int id, {bool forceRefresh = false}) async {
    calls.add('details');
    if (failDetails) throw const NetworkException();
    return Anime(malId: id, title: 'Full', synopsis: 'Story');
  }

  @override
  Future<List<AnimeCharacter>> characters(
    int id, {
    bool forceRefresh = false,
  }) async {
    calls.add('characters');
    if (failCharacters) throw const ServerException(statusCode: 504);
    return const [AnimeCharacter(malId: 1, name: 'Hero', role: 'Main')];
  }

  @override
  Future<List<AnimeRecommendation>> recommendations(
    int id, {
    bool forceRefresh = false,
  }) async {
    calls.add('recommendations');
    return const [];
  }
}

void main() {
  test('shows the preview, then full details and related lists', () async {
    final repo = _FakeRepository();
    final controller = AnimeDetailsController(
      malId: 5,
      detailsRepository: repo,
      preview: const Anime(malId: 5, title: 'Preview'),
    );
    expect(controller.anime?.title, 'Preview');

    await controller.load();

    expect(controller.anime?.title, 'Full');
    expect(controller.hasFullDetails, isTrue);
    expect(controller.characters, isA<AsyncData<List<AnimeCharacter>>>());
    expect(repo.calls, ['details', 'characters', 'recommendations']);
  });

  test('keeps the preview and skips related lists on failure', () async {
    final repo = _FakeRepository()..failDetails = true;
    final controller = AnimeDetailsController(
      malId: 5,
      detailsRepository: repo,
      preview: const Anime(malId: 5, title: 'Preview'),
    );

    await controller.load();

    expect(controller.anime?.title, 'Preview');
    expect(controller.error, isA<NetworkException>());
    expect(repo.calls, ['details']);
  });

  test('a failing section does not affect the others', () async {
    final repo = _FakeRepository()..failCharacters = true;
    final controller = AnimeDetailsController(
      malId: 5,
      detailsRepository: repo,
    );

    await controller.load();

    expect(controller.error, isNull);
    expect(controller.characters, isA<AsyncFailure<List<AnimeCharacter>>>());
    expect(
      controller.recommendations,
      isA<AsyncData<List<AnimeRecommendation>>>(),
    );
  });
}
