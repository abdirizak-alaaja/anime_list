typedef Json = Map<String, dynamic>;

/// Lenient readers for Jikan payloads.
///
/// Jikan fields are frequently `null`, missing, or of an unexpected type.
/// Every reader returns `null` (or an empty collection) instead of throwing,
/// so a partially populated entry never crashes the app.
extension JsonRead on Json {
  String? str(String key) {
    final value = this[key];
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  int? integer(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? decimal(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool? boolean(String key) {
    final value = this[key];
    return value is bool ? value : null;
  }

  DateTime? date(String key) {
    final value = str(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  Json? obj(String key) => asJson(this[key]);

  List<Json> objList(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [for (final item in value) ?asJson(item)];
  }

  List<String> strList(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

/// Casts [value] to [Json] if it is a map, otherwise returns `null`.
Json? asJson(Object? value) => switch (value) {
  Json() => value,
  Map() => value.cast<String, dynamic>(),
  _ => null,
};
