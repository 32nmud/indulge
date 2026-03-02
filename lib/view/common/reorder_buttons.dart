import 'package:flutter/material.dart';

/// Compact stacked ↑ / ↓ buttons for reordering items in a list.
/// Uses filled tonal style so they are always visible against any background.
/// Disabled (30 % opacity, non-tappable) at list boundaries.
class ReorderButtons extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const ReorderButtons({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReorderBtn(
          icon: Icons.arrow_upward,
          tooltip: 'Move up',
          disabled: isFirst,
          onTap: isFirst ? null : onUp,
        ),
        const SizedBox(height: 2),
        _ReorderBtn(
          icon: Icons.arrow_downward,
          tooltip: 'Move down',
          disabled: isLast,
          onTap: isLast ? null : onDown,
        ),
      ],
    );
  }
}

class _ReorderBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool disabled;
  final VoidCallback? onTap;

  const _ReorderBtn({
    required this.icon,
    required this.tooltip,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.secondaryContainer;
    final fg = scheme.onSecondaryContainer;

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: disabled ? 0.35 : 1.0,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: Center(child: Icon(icon, size: 16, color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}
