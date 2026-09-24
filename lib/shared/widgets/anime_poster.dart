import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Poster image with a themed placeholder and error fallback.
///
/// Images are cached on disk, and decoded at their display size to keep
/// memory use low on lower-end devices.
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

          // Cached on disk, so posters of saved anime still show offline.
          return CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: width,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (context, url) => placeholder,
            errorWidget: (context, url, error) => placeholder,
            imageBuilder: semanticLabel == null
                ? null
                : (context, provider) => Image(
                    image: provider,
                    fit: fit,
                    semanticLabel: semanticLabel,
                  ),
          );
        },
      ),
    );
  }
}
