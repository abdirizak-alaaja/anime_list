import 'saved_response_store.dart';

/// Platforms without `dart:io` (web) don't keep saved responses.
Future<SavedResponseStore> openSavedResponseStore() async =>
    const NoSavedResponses();
