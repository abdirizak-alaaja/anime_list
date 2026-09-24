import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/paged_list_controller.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/anime_card.dart';
import '../../../shared/widgets/anime_skeletons.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer.dart';

/// A titled, horizontally scrolling row of anime cards.
///
/// Loads further pages as the user nears the end of the row.
class AnimeCarousel extends StatelessWidget {
  const AnimeCarousel({
    super.key,
    required this.title,
    required this.controller,
    this.onAnimeTap,
    this.onSeeAll,
    this.isFavorite,
  });

  final String title;
  final PagedListController<Anime> controller;
  final void Function(Anime anime)? onAnimeTap;
  final VoidCallback? onSeeAll;
  final bool Function(Anime anime)? isFavorite;

  static const _cardWidth = 136.0;

  @override
  Widget build(BuildContext context) {
    final height = AnimeCard.heightFor(
      _cardWidth,
      MediaQuery.textScalerOf(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, actionLabel: 'See all', onAction: onSeeAll),
        SizedBox(
          height: height,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _buildContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = controller.items;
    final error = controller.error;

    if (controller.isInitialLoading || controller.isPristine) {
      return Shimmer(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
          itemBuilder: (_, _) =>
              const SizedBox(width: _cardWidth, child: AnimeCardSkeleton()),
        ),
      );
    }
    if (items.isEmpty && error != null) {
      return ErrorView(error: error, onRetry: controller.retry, compact: true);
    }
    if (items.isEmpty) {
      return const EmptyView(title: 'Nothing here yet', compact: true);
    }

    final showFooter = controller.isLoadingMore || error != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.horizontal &&
            metrics.extentAfter < _cardWidth * 3) {
          controller.loadMore();
        }
        return false;
      },
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        itemCount: items.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return SizedBox(
              width: _cardWidth,
              child: error != null
                  ? Center(
                      child: IconButton.filledTonal(
                        tooltip: 'Retry',
                        onPressed: controller.retry,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            );
          }
          final anime = items[index];
          return SizedBox(
            width: _cardWidth,
            child: AnimeCard(
              anime: anime,
              isFavorite: isFavorite?.call(anime) ?? false,
              onTap: onAnimeTap == null ? null : () => onAnimeTap!(anime),
            ),
          );
        },
      ),
    );
  }
}
