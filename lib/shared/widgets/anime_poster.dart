import 'package:flutter/material.dart';

/// Poster image with a themed placeholder and error fallback.
///
/// Decodes the image at its display size to keep memory use low on
/// lower-end devices.
class AnimePoster extends StatelessWidget {
  const AnimePoster({
    super.key,
    required this.imageUrl,
    this.borderRadius = 10,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  /// Standard poster aspect ratio (width / height).
  static const aspectRatio = 225 / 318;

  final String? imageUrl;
  final double borderRadius;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.movie_filter_outlined,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final url = imageUrl;
          if (url == null) return SizedBox.expand(child: placeholder);

          final dpr = MediaQuery.devicePixelRatioOf(context);
          final width = constraints.hasBoundedWidth
              ? (constraints.maxWidth * dpr).round()
              : null;

          return Image.network(
            url,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: width,
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSyncLoaded) {
              if (wasSyncLoaded) return child;
              return Stack(
                fit: StackFit.expand,
                children: [
                  placeholder,
                  AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: child,
                  ),
                ],
              );
            },
            errorBuilder: (context, error, stackTrace) => placeholder,
          );
        },
      ),
    );
  }
}
