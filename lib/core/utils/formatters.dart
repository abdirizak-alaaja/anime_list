import '../../shared/models/anime_enums.dart';

/// Display helpers for anime metadata.
abstract final class Formatters {
  /// 1234 → "1,234", 1234567 → "1.2M".
  static String compactCount(int value) {
    if (value >= 1000000) return '${_trim(value / 1000000)}M';
    if (value >= 10000) return '${_trim(value / 1000)}K';
    return thousands(value);
  }

  /// 1234567 → "1,234,567".
  static String thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String score(double? score) =>
      score == null ? 'N/A' : score.toStringAsFixed(2);

  /// "12 eps", "1 ep", or "? eps" when unknown.
  static String episodes(int? count) => switch (count) {
    null => '? eps',
    1 => '1 ep',
    _ => '$count eps',
  };

  /// "Fall 2023", "2023", or `null`.
  static String? seasonYear(AnimeSeason? season, int? year) {
    if (year == null) return null;
    return season == null ? '$year' : '${season.label} $year';
  }

  /// Joins the non-null, non-empty parts with a middle dot.
  static String dotted(Iterable<String?> parts) =>
      parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');

  static String _trim(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}
