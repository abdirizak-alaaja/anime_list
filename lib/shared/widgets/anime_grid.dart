import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/state/paged_list_controller.dart';
import '../models/anime.dart';
import 'anime_card.dart';
import 'anime_skeletons.dart';
import 'message_view.dart';
import 'poster_hero.dart';
import 'shimmer.dart';

/// Grid sizing shared by every anime grid.
abstract final class AnimeGridLayout {
  static const maxCardWidth = 170.0;
  static const spacing = Insets.md;

  static SliverGridDelegate delegateFor(double width, TextScaler textScaler) {
    final columns = ((width + spacing) / (maxCardWidth + spacing)).ceil().clamp(
      2,
      8,
    );
    final cardWidth = (width - spacing * (columns - 1)) / columns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: Insets.lg,
      mainAxisExtent: AnimeCard.heightFor(cardWidth, textScaler),
    );
  }
}

/// A sliver grid over a [PagedListController] of anime, with skeletons,
/// empty and error states, and automatic loading of further pages.
class PagedAnimeSliverGrid extends StatelessWidget {
  const PagedAnimeSliverGrid({
    super.key,
    required this.controller,
    required this.onTap,
    required this.heroScope,
    this.emptyTitle = 'No anime found',
    this.emptyMessage,
  });

  final PagedListController<Anime> controller;
  final void Function(Anime anime) onTap;

  /// Scope for poster hero tags; see [posterHeroTag].
  final String heroScope;
  final String emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        final error = controller.error;

        if (controller.isInitialLoading) {
          return const _SkeletonGrid();
        }
        if (items.isEmpty && error != null) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(error: error, onRetry: controller.retry),
          );
        }
        if (items.isEmpty && controller.hasLoaded && controller.hasMore) {
          // Several pages in a row had nothing to show (e.g. very narrow
          // filters); let the user decide whether to keep looking.
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.search_off_rounded,
              title: 'No matches yet',
              message: 'Nothing matched in the results checked so far.',
              action: FilledButton.tonal(
                onPressed: controller.loadMore,
                child: const Text('Keep looking'),
              ),
            ),
          );
        }
        if (controller.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.search_off_rounded,
              title: emptyTitle,
              message: emptyMessage,
            ),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) => SliverGrid.builder(
                  gridDelegate: AnimeGridLayout.delegateFor(
                    constraints.crossAxisExtent,
                    MediaQuery.textScalerOf(context),
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    // Prefetch the next page a few rows before the end.
                    if (index >= items.length - 6) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => controller.loadMore(),
                      );
                    }
                    final anime = items[index];
                    return AnimeCard(
                      anime: anime,
                      heroTag: posterHeroTag(heroScope, anime.malId),
                      onTap: () => onTap(anime),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: _GridFooter(controller: controller)),
          ],
        );
      },
    );
  }
}

class _GridFooter extends StatelessWidget {
  const _GridFooter({required this.controller});

  final PagedListController<Anime> controller;

  @override
  Widget build(BuildContext context) {
    final error = controller.error;
    final Widget child;
    if (controller.isLoadingMore) {
      child = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      child = ErrorView(error: error, onRetry: controller.retry, compact: true);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.all(Insets.xl), child: child);
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) => SliverToBoxAdapter(
          child: Shimmer(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: AnimeGridLayout.delegateFor(
                constraints.crossAxisExtent,
                MediaQuery.textScalerOf(context),
              ),
              itemCount: 9,
              itemBuilder: (_, _) => const AnimeCardSkeleton(),
            ),
          ),
        ),
      ),
    );
  }
}
