import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/json.dart';
import 'saved_response_store.dart';

/// Opens the on-disk store in the app's cache directory.
Future<SavedResponseStore> openSavedResponseStore() async {
  try {
    final cacheDir = await getApplicationCacheDirectory();
    return DiskSavedResponses(Directory('${cacheDir.path}/jikan_responses'));
  } on Object {
    return const NoSavedResponses();
  }
}

/// One JSON file per request in the app's cache directory, bounded to
/// [maxEntries] files (oldest removed first). The OS may also clear the
/// cache directory under storage pressure, which is fine.
class DiskSavedResponses implements SavedResponseStore {
  DiskSavedResponses(this.directory, {this.maxEntries = 200});

  final Directory directory;
  final int maxEntries;
  int _writesSinceTrim = 0;

  @override
  Future<Json?> read(String key) async {
    try {
      final file = _fileFor(key);
      if (!await file.exists()) return null;
      final decoded = asJson(jsonDecode(await file.readAsString()));
      // The file name is a hash; confirm it's really this request.
      if (decoded == null || decoded['key'] != key) return null;
      return asJson(decoded['body']);
    } on Object {
      return null; // Corrupt or unreadable: treat as missing.
    }
  }

  @override
  Future<void> write(String key, Json value) async {
    try {
      await directory.create(recursive: true);
      await _fileFor(key)
          .writeAsString(jsonEncode({'key': key, 'body': value}));
      if (++_writesSinceTrim >= 20) {
        _writesSinceTrim = 0;
        await _trim();
      }
    } on Object {
      // Saving for offline use is best-effort.
    }
  }

  Future<void> _trim() async {
    final files = await directory
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    if (files.length <= maxEntries) return;

    final stats = {for (final f in files) f: (await f.stat()).modified};
    files.sort((a, b) => stats[a]!.compareTo(stats[b]!));
    for (final file in files.take(files.length - maxEntries)) {
      await file.delete();
    }
  }

  File _fileFor(String key) =>
      File('${directory.path}/${_fnv1a(key).toRadixString(16)}.json');

  /// 32-bit FNV-1a hash; collisions are detected on read via the stored key.
  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
