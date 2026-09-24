import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "− 3 / 12 +" control. Tapping the count opens a dialog to type a value.
class EpisodeStepper extends StatelessWidget {
  const EpisodeStepper({
    super.key,
    required this.watched,
    required this.total,
    required this.onChanged,
    this.dense = false,
  });

  final int watched;
  final int? total;
  final ValueChanged<int> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canIncrement = total == null || watched < total!;
    final label = '$watched / ${total ?? '?'}';
    final iconSize = dense ? 20.0 : 24.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Remove an episode',
          iconSize: iconSize,
          visualDensity: dense ? VisualDensity.compact : null,
          onPressed: watched > 0 ? () => onChanged(watched - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Semantics(
          button: true,
          label:
              'Episodes watched: $watched of ${total ?? 'unknown'}. '
              'Tap to edit.',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final value = await _promptEpisodes(context, watched, total);
              if (value != null) onChanged(value);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                label,
                style:
                    (dense
                            ? theme.textTheme.labelLarge
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Add an episode',
          iconSize: iconSize,
          visualDensity: dense ? VisualDensity.compact : null,
          onPressed: canIncrement ? () => onChanged(watched + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

Future<int?> _promptEpisodes(BuildContext context, int watched, int? total) {
  return showDialog<int>(
    context: context,
    builder: (context) => _EpisodeDialog(watched: watched, total: total),
  );
}

class _EpisodeDialog extends StatefulWidget {
  const _EpisodeDialog({required this.watched, required this.total});

  final int watched;
  final int? total;

  @override
  State<_EpisodeDialog> createState() => _EpisodeDialogState();
}

class _EpisodeDialogState extends State<_EpisodeDialog> {
  late final _controller = TextEditingController(text: '${widget.watched}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    final total = widget.total;
    if (value == null || value < 0) {
      setState(() => _error = 'Enter a whole number');
    } else if (total != null && value > total) {
      setState(() => _error = 'This anime has $total episodes');
    } else {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Episodes watched'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: widget.total == null ? null : '/ ${widget.total}',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
