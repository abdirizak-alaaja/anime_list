import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/async_state.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_character.dart';
import '../../../shared/models/anime_recommendation.dart';
import '../repositories/anime_details_repository.dart';

/// Loads an anime's full details, then its characters and recommendations.
///
/// A [preview] (e.g. from the card that was tapped) is shown immediately
/// while the full record loads, and kept if loading fails.
class AnimeDetailsController extends ChangeNotifier {
  AnimeDetailsController({
    required this.malId,
    required AnimeDetailsRepository detailsRepository,
    Anime? preview,
  }) : _repository = detailsRepository,
       _anime = preview;

  final int malId;
  final AnimeDetailsRepository _repository;

  Anime? _anime;
  bool _isLoading = false;
  bool _hasFullDetails = false;
  AppException? _error;
  AsyncState<List<AnimeCharacter>> _characters = const AsyncLoading();
  AsyncState<List<AnimeRecommendation>> _recommendations = const AsyncLoading();
  bool _disposed = false;

  /// Best data available: full details, or the preview until they load.
  Anime? get anime => _anime;
  bool get isLoading => _isLoading;
  bool get hasFullDetails => _hasFullDetails;

  /// Set when the full details failed to load.
  AppException? get error => _error;
  AsyncState<List<AnimeCharacter>> get characters => _characters;
  AsyncState<List<AnimeRecommendation>> get recommendations => _recommendations;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _notify();

    try {
      _anime = await _repository.details(malId, forceRefresh: forceRefresh);
      _hasFullDetails = true;
    } catch (error) {
      _error = AppException.from(error);
    } finally {
      _isLoading = false;
      _notify();
    }

    if (_hasFullDetails) {
      // Sequential on purpose: these are secondary, and spacing them out
      // leaves rate-limit headroom for whatever the user does next.
      await loadCharacters(forceRefresh: forceRefresh);
      await loadRecommendations(forceRefresh: forceRefresh);
    }
  }

  Future<void> loadCharacters({bool forceRefresh = false}) async {
    _characters = const AsyncLoading();
    _notify();
    _characters = await _guard(
      () => _repository.characters(malId, forceRefresh: forceRefresh),
    );
    _notify();
  }

  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    _recommendations = const AsyncLoading();
    _notify();
    _recommendations = await _guard(
      () => _repository.recommendations(malId, forceRefresh: forceRefresh),
    );
    _notify();
  }

  static Future<AsyncState<T>> _guard<T>(Future<T> Function() load) async {
    try {
      return AsyncData(await load());
    } catch (error) {
      return AsyncFailure(AppException.from(error));
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
