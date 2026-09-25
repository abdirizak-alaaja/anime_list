import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/jikan_api.dart';
import '../../../shared/models/anime.dart';

/// Picks a handful of random anime for the featured banner.
class FeaturedController extends ChangeNotifier {
  FeaturedController(this._api, {this.count = 5});

  final JikanApi _api;
  final int count;

  List<Anime> _items = const [];
  List<Anime> get items => _items;

  AppException? _error;
  AppException? get error => _error;

  bool _loading = false;
  int _generation = 0;
  bool _disposed = false;

  /// Loads once; later calls are no-ops unless [refresh] is used.
  Future<void> loadInitial() async {
    if (_items.isNotEmpty || _loading) return;
    await _load();
  }

  /// Replaces the current picks with new random ones.
  Future<AppException?> refresh() async {
    await _load();
    return _error;
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    final picked = <Anime>[];
    // Show picks as they arrive on first load; on refresh keep the old ones
    // until the new set is ready so the banner doesn't shrink.
    final progressive = _items.isEmpty;
    // Allow a few extra draws to make up for skipped entries.
    var attempts = count * 3;

    // Sequential on purpose: identical concurrent requests are merged by
    // the HTTP client, so parallel calls would all return the same entry.
    while (picked.length < count && attempts-- > 0) {
      try {
        final anime = await _api.getRandomAnime();
        if (generation != _generation || _disposed) return;
        if (!_isExplicit(anime) && !picked.contains(anime)) {
          picked.add(anime);
          if (progressive) {
            _items = List.unmodifiable(picked);
            notifyListeners();
          }
        }
      } on AppException catch (error) {
        if (generation != _generation || _disposed) return;
        if (picked.isEmpty) _error = error;
        break;
      }
    }

    if (picked.isNotEmpty) _items = List.unmodifiable(picked);
    _loading = false;
    if (!_disposed) notifyListeners();
  }

  /// `/random/anime` ignores `sfw`, so drop explicit ratings here.
  static bool _isExplicit(Anime anime) {
    final rating = anime.rating;
    return rating != null &&
        (rating.startsWith('Rx') || rating.startsWith('R+'));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
