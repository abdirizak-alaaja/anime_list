import 'package:flutter/foundation.dart';

import '../../../core/storage/key_value_store.dart';

/// Persists the user's most recent search terms, newest first.
class RecentSearchesStore extends ChangeNotifier {
  RecentSearchesStore(this._store) : _terms = _read(_store);

  static const _key = 'search.recent';
  static const maxTerms = 10;

  final KeyValueStore _store;
  List<String> _terms;

  List<String> get terms => _terms;

  Future<void> add(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    _terms = [
      trimmed,
      ..._terms.where((t) => t.toLowerCase() != trimmed.toLowerCase()),
    ].take(maxTerms).toList(growable: false);
    await _save();
  }

  Future<void> remove(String term) async {
    _terms = _terms.where((t) => t != term).toList(growable: false);
    await _save();
  }

  Future<void> clear() async {
    _terms = const [];
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _store.writeJson(_key, _terms);
  }

  static List<String> _read(KeyValueStore store) {
    final json = store.readJson(_key);
    if (json is! List) return const [];
    return json.whereType<String>().take(maxTerms).toList(growable: false);
  }
}
