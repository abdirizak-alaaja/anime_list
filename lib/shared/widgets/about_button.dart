import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// App bar action that shows who built the app.
class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'About',
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _AboutDialog(),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      icon: CircleAvatar(
        radius: 28,
        backgroundColor: scheme.primaryContainer,
        child: Icon(
          Icons.code_rounded,
          size: 28,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: const Text(AppConstants.appName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Developed by',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            'Abdirizak Abdullahi (Alaaja)',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Insets.lg),
          const _Fact(
            icon: Icons.work_outline_rounded,
            text: 'Senior Software Engineer',
          ),
          const _Fact(
            icon: Icons.sensors_rounded,
            text: 'IoT developer, mainly writing in Go',
          ),
          const _Fact(
            icon: Icons.favorite_outline_rounded,
            text: 'Otaku and anime lover',
          ),
          const _Fact(
            icon: Icons.school_outlined,
            text: 'Studies at Somali International University',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: Insets.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
