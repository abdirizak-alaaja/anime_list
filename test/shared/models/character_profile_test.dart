import 'package:anime_list/core/utils/json.dart';
import 'package:anime_list/shared/models/character_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  test('parses a full character profile', () {
    final json = fixture('character_full.json')! as Json;
    final profile = CharacterProfile.fromJson(json.obj('data')!)!;

    expect(profile.name, 'Frieren');
    expect(profile.nameKanji, 'フリーレン');
    expect(profile.nicknames, ['Frieren the Slayer']);
    expect(profile.favorites, 51234);
    expect(profile.imageUrl, contains('525105.jpg'));
    // Main roles first; entries without an id are skipped.
    expect(profile.animeography.map((a) => a.malId), [52991, 56885]);
    expect(profile.animeography.first.imageUrl, contains('138006l.jpg'));
    // Japanese first; the "no picture" placeholder is dropped.
    expect(profile.voiceActors.map((v) => v.name), [
      'Tanezaki, Atsumi',
      'Mallorie Rodak',
    ]);
    expect(profile.voiceActors.last.imageUrl, isNull);
  });

  test('handles sparse data', () {
    final profile = CharacterProfile.fromJson({'mal_id': 1, 'name': 'Bare'})!;
    expect(profile.about, isNull);
    expect(profile.animeography, isEmpty);
    expect(profile.voiceActors, isEmpty);
    expect(CharacterProfile.fromJson({'name': 'No id'}), isNull);
  });
}
