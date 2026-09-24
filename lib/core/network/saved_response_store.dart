import '../utils/json.dart';

/// Keeps the last successful response for each request so it can be shown
/// when the network or Jikan is unavailable.
///
/// Unlike [ResponseCache], entries never expire: an old answer is better
/// than none while offline.
abstract interface class SavedResponseStore {
  Future<Json?> read(String key);

  Future<void> write(String key, Json value);
}

/// Stores nothing. Used where no disk is available (e.g. web).
class NoSavedResponses implements SavedResponseStore {
  const NoSavedResponses();

  @override
  Future<Json?> read(String key) async => null;

  @override
  Future<void> write(String key, Json value) async {}
}

/// In-memory store, for tests.
class InMemorySavedResponses implements SavedResponseStore {
  final Map<String, Json> entries = {};

  @override
  Future<Json?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, Json value) async => entries[key] = value;
}
