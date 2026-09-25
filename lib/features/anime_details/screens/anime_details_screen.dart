import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/expandable_text.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/poster_hero.dart';
import '../../../shared/widgets/section_header.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../library/widgets/library_panel.dart';
import '../controllers/anime_details_controller.dart';
import '../repositories/anime_details_repository.dart';
import '../widgets/details_header.dart';
import '../widgets/info_table.dart';
import '../widgets/media_strip.dart';
import '../widgets/stats_row.dart';
import '../widgets/tag_list.dart';
import '../widgets/trailer_player.dart';

class AnimeDetailsScreen extends StatefulWidget {
  const AnimeDetailsScreen({
    super.key,
    required this.malId,
    this.preview,
    this.heroTag,
  });

  final int malId;
  final Anime? preview;

  /// Hero tag of the poster that was tapped, for the transition.
  final Object? heroTag;

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late final AnimeDetailsController _controller;

  /// Whether the header has scrolled away, so the app bar turns solid.
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    final deps = AppScope.of(context);
    _controller = AnimeDetailsController(
      malId: widget.malId,
      preview: widget.preview,
      detailsRepository: AnimeDetailsRepository(deps.jikan),
    );
    _load();
  }

  /// Loads details and refreshes saved copies in the library and favorites so
  /// it stays accurate offline (e.g. a newly announced episode count).
  Future<void> _load({bool forceRefresh = false}) async {
    final deps = AppScope.of(context);
    await _controller.load(forceRefresh: forceRefresh);
    final anime = _controller.anime;
    if (_controller.hasFullDetails && anime != null) {
      await deps.library.syncMetadata(anime);
      await deps.favorites.syncMetadata(anime);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    // Only the page itself, not the horizontal strips inside it.
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final collapsed = notification.metrics.pixels > _collapseOffset;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    }
    return false;
  }

  /// Roughly where the header's poster ends.
  static const _collapseOffset = 180.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final anime = _controller.anime;
        final error = _controller.error;

        if (anime == null) {
          return Scaffold(
            appBar: AppBar(),
            body: error != null
                ? ErrorView(error: error, onRetry: _load)
                : const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          // Stays pinned: transparent over the header, then solid with the
          // title once the header scrolls away.
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            flexibleSpace: _AppBarBackground(solid: _collapsed),
            // Built only when shown, so the title isn't read or found twice.
            title: AnimatedSwitcher(
              duration: _fade,
              child: _collapsed
                  ? Text(
                      anime.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    )
                  : const SizedBox.shrink(),
            ),
            actions: [FavoriteButton(anime: anime, color: Colors.white)],
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: RefreshIndicator(
              edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
              onRefresh: () => _load(forceRefresh: true),
              child: _DetailsBody(
                controller: _controller,
                anime: anime,
                heroTag: widget.heroTag,
                onRetry: _load,
              ),
            ),
          ),
        );
      },
    );
  }
}

const _fade = Duration(milliseconds: 200);

/// A scrim that keeps icons legible over light posters, fading to the
/// theme's app bar color when [solid].
class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({required this.solid});

  final bool solid;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).appBarTheme.backgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: solid ? 1 : 0,
          duration: _fade,
          child: ColoredBox(color: color ?? Colors.black),
        ),
      ],
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.controller,
    required this.anime,
    required this.onRetry,
    this.heroTag,
  });

  final AnimeDetailsController controller;
  final Anime anime;
  final Object? heroTag;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = controller.error;
    final synopsis = anime.synopsis;
    final background = anime.background;
    const padding = EdgeInsets.symmetric(horizontal: Insets.lg);

    return ListView(
      padding: EdgeInsets.only(
        bottom: Insets.xxl,
        // Keep line lengths readable on tablets and desktop.
        left: _sidePadding(context),
        right: _sidePadding(context),
      ),
      children: [
        DetailsHeader(anime: anime, heroTag: heroTag),
        if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 0),
            child: LinearProgressIndicator(),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              0,
            ),
            child: _InlineError(message: error.message, onRetry: onRetry),
          ),
        const SizedBox(height: Insets.lg),
        Padding(
          padding: padding,
          child: LibraryPanel(anime: anime),
        ),
        const SizedBox(height: Insets.md),
        Padding(
          padding: padding,
          child: StatsRow(anime: anime),
        ),
        if (anime.trailerUri != null) ...[
          const SizedBox(height: Insets.md),
          Padding(
            padding: padding,
            child: TrailerPlayer(anime: anime),
          ),
        ],
        const SectionHeader(title: 'Synopsis'),
        Padding(
          padding: padding,
          child: synopsis == null
              ? Text(
                  controller.hasFullDetails
                      ? 'No synopsis available.'
                      : 'Loading synopsis…',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : ExpandableText(synopsis),
        ),
        const SectionHeader(title: 'Information'),
        Padding(
          padding: padding,
          child: InfoTable(anime: anime),
        ),
        const SizedBox(height: Insets.lg),
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TagList(
                label: 'Genres',
                tags: [for (final g in anime.allGenres) g.name],
                highlight: true,
              ),
              TagList(
                label: 'Studios',
                tags: [for (final s in anime.studios) s.name],
              ),
              TagList(
                label: 'Producers',
                tags: [for (final p in anime.producers) p.name],
              ),
            ],
          ),
        ),
        if (background != null) ...[
          const SectionHeader(title: 'Background'),
          Padding(
            padding: padding,
            child: ExpandableText(background, collapsedLines: 4),
          ),
        ],
        if (controller.hasFullDetails) ...[
          MediaStrip(
            title: 'Characters',
            state: controller.characters,
            onRetry: controller.loadCharacters,
            itemBuilder: (context, character) => CharacterTile(
              character: character,
              onTap: () => AppRouter.openCharacter(context, character),
            ),
          ),
          MediaStrip(
            title: 'Recommendations',
            state: controller.recommendations,
            onRetry: controller.loadRecommendations,
            itemBuilder: (context, rec) => RecommendationTile(
              recommendation: rec,
              heroTag: posterHeroTag('recommendations', rec.malId),
              onTap: () => AppRouter.openAnime(
                context,
                malId: rec.malId,
                heroTag: posterHeroTag('recommendations', rec.malId),
                preview: Anime(
                  malId: rec.malId,
                  title: rec.title,
                  imageUrl: rec.imageUrl,
                  largeImageUrl: rec.imageUrl,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

double _sidePadding(BuildContext context) {
  const maxContentWidth = 900.0;
  final width = MediaQuery.sizeOf(context).width;
  return width > maxContentWidth ? (width - maxContentWidth) / 2 : 0;
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.xs,
          Insets.xs,
          Insets.xs,
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
