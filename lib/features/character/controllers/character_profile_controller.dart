import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/jikan_api.dart';
import '../../../core/state/async_state.dart';
import '../../../shared/models/character_profile.dart';

/// Loads a character's full profile.
class CharacterProfileController extends ChangeNotifier {
  CharacterProfileController({required this.malId, required this._api});

  final int malId;
  final JikanApi _api;

  AsyncState<CharacterProfile> _profile = const AsyncLoading();
  bool _disposed = false;

  AsyncState<CharacterProfile> get profile => _profile;

  /// Keeps showing the current profile while a refresh is in flight.
  Future<void> load({bool forceRefresh = false}) async {
    if (_profile is! AsyncData) {
      _profile = const AsyncLoading();
      _notify();
    }
    try {
      _profile = AsyncData(
        await _api.getCharacterFull(malId, forceRefresh: forceRefresh),
      );
    } catch (error) {
      _profile = AsyncFailure(AppException.from(error));
    }
    _notify();
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
