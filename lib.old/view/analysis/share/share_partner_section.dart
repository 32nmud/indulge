import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/share/share_card_models.dart';
import 'package:indulge/view/common/share/share_card_theme.dart';

// ── Partner bar row ───────────────────────────────────────────────────────────

class SharePartnerBarRow extends StatelessWidget {
  final PartnerRowData row;
  final int maxEvents;
  final bool privacyMode;

  const SharePartnerBarRow({
    super.key,
    required this.row,
    required this.maxEvents,
    this.privacyMode = false,
  });

  String _displayName(Person p) =>
      p.name.nickname ?? p.name.given ?? p.name.family ?? 'Unknown';

  String _initials(Person p) {
    final nick = p.name.nickname ?? '';
    final given = p.name.given ?? '';
    final family = p.name.family ?? '';
    if (nick.isNotEmpty) return nick[0].toUpperCase();
    if (given.isNotEmpty && family.isNotEmpty) {
      return '${given[0]}${family[0]}'.toUpperCase();
    }
    if (given.isNotEmpty) return given[0].toUpperCase();
    return '?';
  }

  Uint8List? _avatar(Person p) {
    final raw = p.imageBytes;
    if (raw == null || raw.isEmpty) return null;
    try {
      final bytes = base64Decode(raw);
      return bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  /// Consistent pastel colour for a numbered anonymous partner.
  static Color _anonColor(int index) {
    const palette = [
      Color(0xFF7C6FCD),
      Color(0xFF4DB6AC),
      Color(0xFFAB47BC),
      Color(0xFF4FC3F7),
      Color(0xFFFF8A65),
      Color(0xFFAED581),
    ];
    return palette[(index - 1) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final fraction = maxEvents > 0
        ? (row.eventCount / maxEvents).clamp(0.0, 1.0)
        : 0.0;
    final fillFlex = (fraction * 1000).round().clamp(1, 1000);
    final emptyFlex = (1000 - fillFlex).clamp(0, 999);

    final String nameLabel = privacyMode
        ? 'Partner ${row.anonymousIndex}'
        : _displayName(row.person);

    final Widget avatarWidget = privacyMode
        ? CircleAvatar(
            radius: 18,
            backgroundColor: _anonColor(row.anonymousIndex).withOpacity(0.35),
            child: Text(
              '${row.anonymousIndex}',
              style: TextStyle(
                color: _anonColor(row.anonymousIndex),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : Builder(
            builder: (_) {
              final avatarBytes = _avatar(row.person);
              return CircleAvatar(
                radius: 18,
                backgroundColor: ShareCardTheme.accent.withOpacity(0.3),
                backgroundImage: avatarBytes != null
                    ? MemoryImage(avatarBytes)
                    : null,
                child: avatarBytes == null
                    ? Text(
                        _initials(row.person),
                        style: const TextStyle(
                          color: ShareCardTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              );
            },
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          avatarWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nameLabel,
                        style: const TextStyle(
                          color: ShareCardTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShareCountBadge(
                      value: '${row.eventCount}',
                      label: row.eventCount == 1 ? 'event' : 'events',
                      color: ShareCardTheme.couple,
                    ),
                    if (row.activityCount > 0) ...[
                      const SizedBox(width: 6),
                      ShareCountBadge(
                        value: '${row.activityCount}',
                        label: 'acts.',
                        color: ShareCardTheme.riskModerate,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: fillFlex,
                          child: Container(
                            color: privacyMode
                                ? _anonColor(row.anonymousIndex)
                                : ShareCardTheme.couple,
                          ),
                        ),
                        if (emptyFlex > 0)
                          Expanded(
                            flex: emptyFlex,
                            child: Container(color: ShareCardTheme.surfaceHigh),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class ShareCountBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const ShareCountBadge({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
