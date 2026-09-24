import 'dart:collection';

import '../utils/json.dart';

/// Stores decoded API responses by request key.
abstract interface class ResponseCache {
  /// Returns a cached response that hasn't expired, or `null`.
  Json? get(String key);

  void put(String key, Json value, Duration ttl);

  void clear();
}

/// Bounded in-memory LRU cache with per-entry expiry.
class MemoryResponseCache implements ResponseCache {
  MemoryResponseCache({this.maxEntries = 120, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final int maxEntries;
  final DateTime Function() _now;

  // LinkedHashMap keeps insertion order; re-inserting on read makes it LRU.
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();

  @override
  Json? get(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    if (_now().isAfter(entry.expiresAt)) return null;
    _entries[key] = entry;
    return entry.value;
  }

  @override
  void put(String key, Json value, Duration ttl) {
    _entries.remove(key);
    _entries[key] = _Entry(value, _now().add(ttl));
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  @override
  void clear() => _entries.clear();
}

class _Entry {
  const _Entry(this.value, this.expiresAt);

  final Json value;
  final DateTime expiresAt;
}
