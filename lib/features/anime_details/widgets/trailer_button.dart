import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/anime.dart';

/// Opens the anime's trailer on YouTube (the app if installed, else the
/// browser). Renders nothing when there is no trailer.
class TrailerButton extends StatelessWidget {
  const TrailerButton({super.key, required this.anime});

  final Anime anime;

  Future<void> _open(BuildContext context, Uri uri) async {
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
    final uri = anime.trailerUri;
    if (uri == null) return const SizedBox.shrink();
    return FilledButton.tonalIcon(
      onPressed: () => _open(context, uri),
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Watch trailer'),
    );
  }
}
