import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/paged_list_controller.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/anime_grid.dart';

/// Full, infinitely scrolling grid for one discovery list.
///
/// Shares the [controller] with the home carousel, so already-loaded pages
/// aren't fetched again.
class AnimeCollectionScreen extends StatefulWidget {
  const AnimeCollectionScreen({
    super.key,
    required this.title,
    required this.controller,
    required this.heroScope,
    this.subtitle,
    this.onAnimeTap,
  });

  final String title;
  final String? subtitle;
  final PagedListController<Anime> controller;
  final String heroScope;
  final void Function(Anime anime)? onAnimeTap;

  @override
  State<AnimeCollectionScreen> createState() => _AnimeCollectionScreenState();
}

class _AnimeCollectionScreenState extends State<AnimeCollectionScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadInitial();
  }

  Future<void> _refresh() async {
    final error = await widget.controller.refresh();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            if (subtitle != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.lg,
                  Insets.lg,
                  Insets.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            PagedAnimeSliverGrid(
              controller: widget.controller,
              heroScope: widget.heroScope,
              onTap: (anime) => widget.onAnimeTap?.call(anime),
            ),
          ],
        ),
      ),
    );
  }
}
