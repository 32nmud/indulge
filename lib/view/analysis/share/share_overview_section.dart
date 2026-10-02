import 'package:flutter/material.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';

// ── Stat cell (large number + label) ─────────────────────────────────────────

class ShareStatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const ShareStatCell({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: ShareCardTheme.surface,
        borderRadius: BorderRadius.circular(ShareCardTheme.sectionRadius),
        border: Border.all(color: ShareCardTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                color: ShareCardTheme.textMuted,
                fontSize: 18,
                height: 1.2,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: ShareCardTheme.textSecondary,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Average cell (value + label side by side) ─────────────────────────────────

class ShareAverageCell extends StatelessWidget {
  final String label;
  final String value;

  const ShareAverageCell({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ShareCardTheme.surface,
        borderRadius: BorderRadius.circular(ShareCardTheme.sectionRadius),
        border: Border.all(color: ShareCardTheme.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ShareCardTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ShareCardTheme.textSecondary,
                fontSize: 18,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
