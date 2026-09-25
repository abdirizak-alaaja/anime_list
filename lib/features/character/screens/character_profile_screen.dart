import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/state/async_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_character.dart';
import '../../../shared/models/character_profile.dart';
import '../../../shared/widgets/anime_poster.dart';
import '../../../shared/widgets/expandable_text.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/poster_hero.dart';
import '../../../shared/widgets/section_header.dart';
import '../../anime_details/widgets/media_strip.dart';
import '../../anime_details/widgets/tag_list.dart';
import '../controllers/character_profile_controller.dart';

/// A character's portrait, bio, voice actors and the anime they appear in.
class CharacterProfileScreen extends StatefulWidget {
  const CharacterProfileScreen({super.key, required this.malId, this.preview});

  final int malId;

  /// Shown immediately while the full profile loads.
  final AnimeCharacter? preview;

  @override
  State<CharacterProfileScreen> createState() => _CharacterProfileScreenState();
}

class _CharacterProfileScreenState extends State<CharacterProfileScreen> {
  late final CharacterProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CharacterProfileController(
      malId: widget.malId,
      api: AppScope.of(context).jikan,
    )..load();
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
        final state = _controller.profile;
        final profile = switch (state) {
          AsyncData(:final value) => value,
          _ => null,
        };
        final preview = widget.preview;
        final name = profile?.name ?? preview?.name;

        if (name == null) {
          return Scaffold(
            appBar: AppBar(),
            body: switch (state) {
              AsyncFailure(:final error) => ErrorView(
                error: error,
                onRetry: _controller.load,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: RefreshIndicator(
            onRefresh: () => _controller.load(forceRefresh: true),
            child: _ProfileBody(
              name: name,
              imageUrl: profile?.imageUrl ?? preview?.imageUrl,
              profile: profile,
              state: state,
              onRetry: _controller.load,
            ),
          ),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.name,
    required this.imageUrl,
    required this.profile,
    required this.state,
    required this.onRetry,
  });

  final String name;
  final String? imageUrl;
  final CharacterProfile? profile;
  final AsyncState<CharacterProfile> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    final about = profile?.about;
    const padding = EdgeInsets.symmetric(horizontal: Insets.lg);

    return ListView(
      padding: EdgeInsets.only(
        bottom: Insets.xxl,
        left: _sidePadding(context),
        right: _sidePadding(context),
      ),
      children: [
        _Header(name: name, imageUrl: imageUrl, profile: profile),
        switch (state) {
          AsyncLoading() => const Padding(
            padding: EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, 0),
            child: LinearProgressIndicator(),
          ),
          AsyncFailure(:final error) => ErrorView(
            error: error,
            onRetry: onRetry,
            compact: true,
          ),
          AsyncData() => const SizedBox.shrink(),
        },
        if (profile != null) ...[
          if (profile.nicknames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.lg,
                Insets.lg,
                0,
              ),
              child: TagList(label: 'Nicknames', tags: profile.nicknames),
            ),
          const SectionHeader(title: 'About'),
          Padding(
            padding: padding,
            child: about == null
                ? Text(
                    'No biography available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                : ExpandableText(about, collapsedLines: 8),
          ),
          MediaStrip<CharacterVoice>(
            title: 'Voice actors',
            state: AsyncData(profile.voiceActors),
            onRetry: onRetry,
            itemBuilder: (context, voice) => _PortraitTile(
              imageUrl: voice.imageUrl,
              title: voice.name,
              subtitle: voice.language,
            ),
          ),
          MediaStrip<CharacterAppearance>(
            title: 'Anime',
            state: AsyncData(profile.animeography),
            onRetry: onRetry,
            itemBuilder: (context, appearance) {
              final heroTag = posterHeroTag(
                'character:${profile.malId}',
                appearance.malId,
              );
              return _PortraitTile(
                imageUrl: appearance.imageUrl,
                title: appearance.title,
                subtitle: appearance.role,
                heroTag: heroTag,
                onTap: () => AppRouter.openAnime(
                  context,
                  malId: appearance.malId,
                  heroTag: heroTag,
                  preview: Anime(
                    malId: appearance.malId,
                    title: appearance.title,
                    imageUrl: appearance.imageUrl,
                    largeImageUrl: appearance.imageUrl,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, this.imageUrl, this.profile});

  final String name;
  final String? imageUrl;
  final CharacterProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final kanji = profile?.nameKanji;
    final favorites = profile?.favorites;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: isWide ? 200 : 132,
            child: AspectRatio(
              aspectRatio: AnimePoster.aspectRatio,
              child: AnimePoster(
                imageUrl: imageUrl,
                borderRadius: 12,
                semanticLabel: '$name portrait',
              ),
            ),
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(name, style: theme.textTheme.headlineSmall),
                if (kanji != null) ...[
                  const SizedBox(height: Insets.xs),
                  SelectableText(
                    kanji,
                    style: theme.textTheme.titleSmall?.copyWith(color: muted),
                  ),
                ],
                if (favorites != null) ...[
                  const SizedBox(height: Insets.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: AppColors.favorite,
                      ),
                      const SizedBox(width: Insets.xs),
                      Text(
                        '${Formatters.thousands(favorites)} favorites',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Portrait or poster with a title and a muted subtitle.
class _PortraitTile extends StatelessWidget {
  const _PortraitTile({
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.heroTag,
    this.onTap,
  });

  final String? imageUrl;
  final String title;
  final String? subtitle;
  final Object? heroTag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;

    return Semantics(
      button: onTap != null,
      label: [title, ?subtitle].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: AnimePoster.aspectRatio,
              child: PosterHero(
                tag: heroTag,
                child: AnimePoster(imageUrl: imageUrl),
              ),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

double _sidePadding(BuildContext context) {
  const maxContentWidth = 900.0;
  final width = MediaQuery.sizeOf(context).width;
  return width > maxContentWidth ? (width - maxContentWidth) / 2 : 0;
}
