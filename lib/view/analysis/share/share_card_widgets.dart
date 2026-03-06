import 'package:flutter/material.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';

// ── Decorative background circle ──────────────────────────────────────────────

class ShareCardCircle extends StatelessWidget {
  final double size;
  final Color color;

  const ShareCardCircle({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ── Empty state placeholder ───────────────────────────────────────────────────

class ShareCardEmptyState extends StatelessWidget {
  final String message;

  const ShareCardEmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      message,
      style: const TextStyle(
        color: ShareCardTheme.textMuted,
        fontSize: 18,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

// ── Time-window label chip ────────────────────────────────────────────────────

class ShareCardSectionLabel extends StatelessWidget {
  final String text;

  const ShareCardSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: ShareCardTheme.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ShareCardTheme.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 14, color: ShareCardTheme.accent),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: ShareCardTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section heading (icon + uppercase title) ──────────────────────────────────

class ShareCardSectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const ShareCardSectionHeading({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ShareCardTheme.accent),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: ShareCardTheme.textSecondary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Event-type legend dot ─────────────────────────────────────────────────────

class ShareCardTypeLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const ShareCardTypeLegendDot({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: ShareCardTheme.textSecondary,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
