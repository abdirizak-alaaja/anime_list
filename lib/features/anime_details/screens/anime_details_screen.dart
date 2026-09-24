import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/expandable_text.dart';
import '../../../shared/widgets/message_view.dart';
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

class AnimeDetailsScreen extends StatefulWidget {
  const AnimeDetailsScreen({super.key, required this.malId, this.preview});

  final int malId;
  final Anime? preview;

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late final AnimeDetailsController _controller;

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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            flexibleSpace: const _AppBarScrim(),
            actions: [FavoriteButton(anime: anime, color: Colors.white)],
          ),
          body: RefreshIndicator(
            edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
            onRefresh: () => _load(forceRefresh: true),
            child: _DetailsBody(
              controller: _controller,
              anime: anime,
              onRetry: _load,
            ),
          ),
        );
      },
    );
  }
}

/// Keeps app bar icons legible over light posters.
class _AppBarScrim extends StatelessWidget {
  const _AppBarScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.controller,
    required this.anime,
    required this.onRetry,
  });

  final AnimeDetailsController controller;
  final Anime anime;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = controller.error;
    final synopsis = anime.synopsis;
    final background = anime.background;
    const padding = EdgeInsets.symmetric(horizontal: Insets.lg);

    return ListView(
      padding: const EdgeInsets.only(bottom: Insets.xxl),
      children: [
        DetailsHeader(anime: anime),
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
            itemBuilder: (context, character) =>
                CharacterTile(character: character),
          ),
          MediaStrip(
            title: 'Recommendations',
            state: controller.recommendations,
            onRetry: controller.loadRecommendations,
            itemBuilder: (context, rec) => RecommendationTile(
              recommendation: rec,
              onTap: () => AppRouter.openAnime(
                context,
                malId: rec.malId,
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
