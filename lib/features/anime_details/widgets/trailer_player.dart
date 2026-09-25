import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../shared/models/anime.dart';

/// Plays the anime's trailer inline with the YouTube embed player.
///
/// Shows the video thumbnail until tapped, so the web view is only created
/// when the user actually wants to watch. Platforms without web view support
/// (Linux, Windows) open the trailer on YouTube instead. Renders nothing when
/// there is no trailer.
class TrailerPlayer extends StatefulWidget {
  const TrailerPlayer({super.key, required this.anime});

  final Anime anime;

  /// Whether the embed player can run on this platform.
  static bool get canEmbed =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  YoutubePlayerController? _controller;

  @override
  void didUpdateWidget(TrailerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anime.trailerYoutubeId != widget.anime.trailerYoutubeId) {
      _controller?.close();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _play(String videoId) {
    if (!TrailerPlayer.canEmbed) {
      _openExternally();
      return;
    }
    setState(() {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
    });
  }

  Future<void> _openExternally() async {
    final uri = widget.anime.trailerUri;
    if (uri == null) return;
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      opened = false;
    }
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't open the trailer.")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = widget.anime.trailerYoutubeId;
    if (videoId == null) return const SizedBox.shrink();
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: controller == null
          ? _Thumbnail(videoId: videoId, onTap: () => _play(videoId))
          : YoutubePlayer(
              controller: controller,
              backgroundColor: Colors.black,
            ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.videoId, required this.onTap});

  final String videoId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Semantics(
        button: true,
        label: 'Play trailer',
        child: Material(
          color: Colors.black,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black26),
                ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 36,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(
                    'Watch trailer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4)],
                    ),
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
