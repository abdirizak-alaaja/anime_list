import 'package:anime_list/core/utils/formatters.dart';
import 'package:anime_list/core/utils/json.dart';
import 'package:anime_list/shared/models/anime_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats counts', () {
    expect(Formatters.thousands(0), '0');
    expect(Formatters.thousands(1234567), '1,234,567');
    expect(Formatters.compactCount(9999), '9,999');
    expect(Formatters.compactCount(15300), '15.3K');
    expect(Formatters.compactCount(1479110), '1.5M');
    expect(Formatters.compactCount(2000000), '2M');
  });

  test('formats anime metadata', () {
    expect(Formatters.score(null), 'N/A');
    expect(Formatters.score(9.1), '9.10');
    expect(Formatters.episodes(null), '? eps');
    expect(Formatters.episodes(1), '1 ep');
    expect(Formatters.episodes(24), '24 eps');
    expect(Formatters.seasonYear(AnimeSeason.fall, 2023), 'Fall 2023');
    expect(Formatters.seasonYear(null, 2023), '2023');
    expect(Formatters.seasonYear(AnimeSeason.fall, null), isNull);
    expect(Formatters.dotted(['TV', null, '', '12 eps']), 'TV · 12 eps');
  });

  test('lenient JSON readers never throw on bad types', () {
    final Json json = {
      'n': '12',
      'd': 7,
      's': '  ',
      'l': 'not a list',
      'o': [1],
      'date': 'garbage',
    };
    expect(json.integer('n'), 12);
    expect(json.decimal('d'), 7.0);
    expect(json.str('s'), isNull);
    expect(json.objList('l'), isEmpty);
    expect(json.obj('o'), isNull);
    expect(json.date('date'), isNull);
    expect(json.boolean('missing'), isNull);
  });
}
