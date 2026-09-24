import 'package:flutter/widgets.dart';

/// Hero tag for a poster shown in [scope] (a screen or section name).
///
/// The scope keeps tags unique when the same anime appears in several
/// places on one screen (e.g. two carousels), which Hero requires.
String posterHeroTag(String scope, int malId) => 'poster:$scope:$malId';

/// Wraps [child] in a [Hero] when [tag] is set.
class PosterHero extends StatelessWidget {
  const PosterHero({super.key, required this.tag, required this.child});

  final Object? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    if (tag == null) return child;
    return Hero(tag: tag, transitionOnUserGestures: true, child: child);
  }
}
