import '../../core/utils/json.dart';

/// A MyAnimeList entity referenced by id and name (genre, studio, producer).
class NamedResource {
  const NamedResource({required this.malId, required this.name, this.count});

  final int malId;
  final String name;

  /// Number of entries, when Jikan provides it (e.g. for genres).
  final int? count;

  static NamedResource? fromJson(Json json) {
    final id = json.integer('mal_id');
    final name = json.str('name');
    if (id == null || name == null) return null;
    return NamedResource(malId: id, name: name, count: json.integer('count'));
  }

  static List<NamedResource> listFrom(List<Json> items) => [
    for (final item in items) ?fromJson(item),
  ];

  @override
  bool operator ==(Object other) =>
      other is NamedResource && other.malId == malId && other.name == name;

  @override
  int get hashCode => Object.hash(malId, name);
}
