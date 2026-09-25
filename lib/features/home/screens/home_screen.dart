import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/poster_hero.dart';
import '../../../shared/widgets/theme_mode_button.dart';
import '../controllers/featured_controller.dart';
import '../controllers/home_controller.dart';
import '../models/discovery_section.dart';
import '../repositories/discovery_repository.dart';
import '../widgets/anime_carousel.dart';
import '../widgets/featured_banner.dart';
import 'anime_collection_screen.dart';

/// Discover tab: a featured banner followed by curated carousels.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  late final FeaturedController _featured;

  @override
  void initState() {
    super.initState();
    final jikan = AppScope.of(context).jikan;
    _controller = HomeController(DiscoveryRepository(jikan))..loadAll();
    _featured = FeaturedController(jikan)..loadInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    _featured.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final (error, _) = await (
      _controller.refreshAll(),
      _featured.refresh(),
    ).wait;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openAnime(Anime anime, {String? heroScope}) =>
      AppRouter.openAnimePreview(
        context,
        anime,
        heroTag: heroScope == null
            ? null
            : posterHeroTag(heroScope, anime.malId),
      );

  void _openSection(DiscoverySection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimeCollectionScreen(
          title: section.title,
          subtitle: section.description,
          controller: _controller[section],
          heroScope: 'all-${section.name}',
          onAnimeTap: (anime) =>
              _openAnime(anime, heroScope: 'all-${section.name}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              title: _AppTitle(),
              actions: [ThemeModeButton()],
            ),
            SliverToBoxAdapter(
              child: FeaturedBanner(controller: _featured, onTap: _openAnime),
            ),
            SliverList.list(
              children: [
                for (final section in DiscoverySection.values)
                  AnimeCarousel(
                    title: section.title,
                    controller: _controller[section],
                    heroScope: section.name,
                    onAnimeTap: (anime) =>
                        _openAnime(anime, heroScope: section.name),
                    onSeeAll: () => _openSection(section),
                  ),
                const SizedBox(height: Insets.xl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_circle_fill_rounded),
        const SizedBox(width: Insets.sm),
        Text(AppConstants.appName, style: DefaultTextStyle.of(context).style),
      ],
    );
  }
}
