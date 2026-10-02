import 'package:flutter/material.dart';

/// A widget that automatically scrolls text horizontally when it overflows,
/// creating a marquee/ticker effect.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final Duration pauseDuration;
  final double gap;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 50),
    this.pauseDuration = const Duration(seconds: 2),
    this.gap = 50.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollController.jumpTo(0);
      _startScrolling();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startScrolling() async {
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Check if text actually overflows
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final containerWidth = context.size?.width ?? 0;
    final textWidth = textPainter.width;

    if (textWidth <= containerWidth) {
      // Text fits, no need to scroll
      return;
    }

    if (!mounted || _isScrolling) return;
    _isScrolling = true;

    try {
      while (mounted && _isScrolling) {
        // Pause at the start
        await Future.delayed(widget.pauseDuration);
        if (!mounted || !_isScrolling) break;

        // Calculate scroll distance
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) break;

        // Scroll to the end
        final scrollDuration = widget.speed * (maxScroll / 10).ceil();
        await _scrollController.animateTo(
          maxScroll,
          duration: scrollDuration,
          curve: Curves.linear,
        );

        if (!mounted || !_isScrolling) break;

        // Pause at the end
        await Future.delayed(widget.pauseDuration);
        if (!mounted || !_isScrolling) break;

        // Scroll back to the start
        await _scrollController.animateTo(
          0,
          duration: scrollDuration,
          curve: Curves.linear,
        );
      }
    } catch (e) {
      // Controller disposed or other error, just stop
      _isScrolling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              Text(
                widget.text,
                style: widget.style,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
              SizedBox(width: widget.gap),
            ],
          ),
        );
      },
    );
  }
}
