import 'package:flutter/material.dart';

/// Reader-chosen text size for the whole site (100%, 115%, 130%).
final textSizeChoice = ValueNotifier<double>(1.0);

const _steps = [1.0, 1.15, 1.3];

/// Applies the chosen text size on top of the device setting.
class TextSizeScope extends StatelessWidget {
  const TextSizeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: textSizeChoice,
    builder: (context, factor, child) {
      if (factor == 1.0) return child!;
      final mq = MediaQuery.of(context);
      final base = mq.textScaler.scale(16) / 16;
      return MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(base * factor)),
        child: child!,
      );
    },
    child: child,
  );
}

/// Header button that steps the text size up and back to normal.
class TextSizeButton extends StatelessWidget {
  const TextSizeButton({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: textSizeChoice,
    builder: (context, factor, _) {
      final i = _steps.indexOf(factor);
      final next = _steps[(i + 1) % _steps.length];
      return IconButton(
        tooltip:
            'Text size ${(factor * 100).round()}%. Change to ${(next * 100).round()}%',
        icon: Icon(
          Icons.format_size_rounded,
          color: factor == 1.0 ? null : Theme.of(context).colorScheme.primary,
        ),
        isSelected: factor != 1.0,
        onPressed: () => textSizeChoice.value = next,
      );
    },
  );
}
