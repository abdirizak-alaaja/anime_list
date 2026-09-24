import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal persistent key-value storage.
///
/// Wraps [SharedPreferences] so repositories don't depend on the plugin
/// directly and can be tested with [InMemoryKeyValueStore].
abstract interface class KeyValueStore {
  String? getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  Iterable<String> get keys;
}

extension KeyValueStoreJson on KeyValueStore {
  /// Reads and decodes JSON stored under [key], or `null` if it's missing or
  /// corrupt.
  Object? readJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Object? value) =>
      setString(key, jsonEncode(value));
}

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Iterable<String> get keys => _prefs.getKeys();
}

class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial])
    : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Iterable<String> get keys => _values.keys;
}
