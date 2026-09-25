import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/anime_poster.dart';
import '../../../shared/widgets/score_badge.dart';
import '../../../shared/widgets/shimmer.dart';
import '../controllers/featured_controller.dart';

/// Swipeable spotlight of a few random anime.
///
/// Hidden if nothing could be loaded.
class FeaturedBanner extends StatefulWidget {
  const FeaturedBanner({super.key, required this.controller, this.onTap});

  final FeaturedController controller;
  final void Function(Anime anime)? onTap;

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  final _pageController = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).width >= 600 ? 280.0 : 210.0;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.items;
        // Picks can be replaced on refresh; keep the page index valid.
        if (_page >= items.length) _page = 0;

        if (items.isEmpty) {
          if (widget.controller.error != null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              0,
            ),
            child: Shimmer(
              child: SkeletonBox(height: height, borderRadius: 16),
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: Insets.md),
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
                  child: _FeaturedItem(
                    anime: items[index],
                    onTap: widget.onTap == null
                        ? null
                        : () => widget.onTap!(items[index]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Insets.sm),
            _PageDots(count: items.length, current: _page),
          ],
        );
      },
    );
  }
}

class _FeaturedItem extends StatelessWidget {
  const _FeaturedItem({required this.anime, this.onTap});

  final Anime anime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genres = anime.genres.take(3).map((g) => g.name);

    return Semantics(
      button: onTap != null,
      label: 'Featured: ${anime.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.black,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimePoster(
                  imageUrl: anime.largeImageUrl ?? anime.imageUrl,
                  borderRadius: 0,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.25, 1],
                      colors: [Colors.transparent, Color(0xE6000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: Insets.lg,
                  right: Insets.lg,
                  bottom: Insets.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScoreBadge(score: anime.score),
                      const SizedBox(height: Insets.sm),
                      Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: Insets.xs),
                      Text(
                        Formatters.dotted([
                          anime.type,
                          if (anime.episodes != null)
                            Formatters.episodes(anime.episodes),
                          ...genres,
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == current ? scheme.primary : scheme.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
