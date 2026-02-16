/*
  Simplified SpeedDial FAB

  - Renders a vertical speed-dial in the Scaffold FAB slot.
  - Expands into labeled action pills (label chip + mini FAB).
  - Uses the app's FloatingActionButtonTheme colors.
  - Keeps a small staggered animation for items.
*/

import 'package:flutter/material.dart';

class SpeedDialItem {
  final Widget? icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const SpeedDialItem({
    this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });
}

class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialItem> items;
  final IconData closedIcon;
  final IconData openedIcon;
  final Duration animationDuration;
  final double spacing;

  const SpeedDialFab({
    super.key,
    required this.items,
    this.closedIcon = Icons.add,
    this.openedIcon = Icons.close,
    this.animationDuration = const Duration(milliseconds: 250),
    this.spacing = 12.0,
  }) : assert(items.length > 0);

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _expand = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_open) {
      setState(() {
        _open = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fabTheme = theme.floatingActionButtonTheme;
    final bg = fabTheme.backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = fabTheme.foregroundColor ?? theme.colorScheme.onPrimaryContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ..._buildItems(bg, fg),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: bg,
          foregroundColor: fg,
          child: AnimatedRotation(
            duration: widget.animationDuration,
            turns: _open ? 0.25 : 0,
            child: Icon(_open ? widget.openedIcon : widget.closedIcon),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems(Color backgroundColor, Color foregroundColor) {
    final items = widget.items;
    // Render reversed so the first item in the list appears closest to FAB.
    final generated = List<Widget>.generate(items.length, (index) {
      final item = items[index];
      // Stagger each item's animation interval (items closer to FAB animate last).
      final int reverseIndex = items.length - 1 - index;
      final double start = (reverseIndex * 0.05).clamp(0.0, 0.6);
      final double end = (start + 0.5).clamp(0.0, 1.0);

      return AnimatedBuilder(
        animation: _expand,
        builder: (context, child) {
          final progress = CurvedAnimation(
            parent: _expand,
            curve: Interval(start, end, curve: Curves.easeOut),
          ).value;
          final opacity = progress;
          final offsetY = 20.0 * (1 - progress);

          // Prevent taps on mini FABs / label when the item is not visible.
          // Use a small threshold rather than exact zero to avoid precision issues.
          final isInteractive = progress > 0.01;

          return IgnorePointer(
            ignoring: !isInteractive,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: child,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.spacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: item.backgroundColor ?? backgroundColor,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    item.onPressed();
                    _close();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'speed_dial_item_$index',
                onPressed: () {
                  item.onPressed();
                  _close();
                },
                backgroundColor: item.backgroundColor ?? backgroundColor,
                foregroundColor: foregroundColor,
                child: item.icon ?? const Icon(Icons.event),
              ),
            ],
          ),
        ),
      );
    });

    return generated.reversed.toList();
  }
}
