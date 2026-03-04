import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// A self-contained, fixed-size widget designed to be captured as an image
/// and shared via the platform share sheet.
///
/// This widget is intentionally decoupled from any Provider / context
/// dependencies so it can be rendered off-screen inside a [RepaintBoundary]
/// without side effects.
///
/// The card width is fixed at [cardWidth] logical pixels; height is intrinsic
/// (grows to fit content). Capture it at pixelRatio 3.0 to produce a
/// 1080 px wide image suitable for social media sharing.
class SexualEventShareCard extends StatelessWidget {
  static const double cardWidth = 360.0;

  final SexualEvent event;
  final List<Person> persons;
  final Map<String, SexualActivityCategory> categories;

  /// When false, participant names are replaced with "Person 1", "Person 2", …
  final bool showPartnerNames;

  /// When false, activity names are hidden; only their emojis are shown.
  final bool showActivityNames;

  const SexualEventShareCard({
    super.key,
    required this.event,
    required this.persons,
    required this.categories,
    this.showPartnerNames = true,
    this.showActivityNames = true,
  });

  // ── Palette ───────────────────────────────────────────────────────────────

  static const Color _bgTop = Color(0xFF1A1040);
  static const Color _bgBottom = Color(0xFF0D0D1A);
  static const Color _accentColor = Color(0xFF7C6FCD);
  static const Color _surfaceColor = Color(0xFF252040);

  static const Color _textPrimary = Color(0xFFF0EEFF);
  static const Color _textSecondary = Color(0xFFADA8CC);
  static const Color _dividerColor = Color(0xFF3A3460);
  static const Color _subcategoryBg = Color(0xFF1E1B38);
  static const Color _subcategoryBorder = Color(0xFF3A3460);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _personDisplayName(Person p, int fallbackIndex) {
    if (!showPartnerNames) return 'Person ${fallbackIndex + 1}';
    return p.name.nickname ?? p.name.given ?? 'Person ${fallbackIndex + 1}';
  }

  bool _isSubcategory(String catRef) {
    for (final parent in categories.values) {
      if (parent.subCategories.any((r) => r.reference == catRef)) return true;
    }
    return false;
  }

  String? _parentCategoryName(String catRef) {
    for (final parent in categories.values) {
      if (parent.subCategories.any((r) => r.reference == catRef)) {
        return parent.name;
      }
    }
    return null;
  }

  // ── Activity data model ───────────────────────────────────────────────────

  /// Mirrors the logic in _SexualEventCardState._buildParticipantsBreakdown
  /// but returns plain data objects instead of widgets.
  List<_ShareActivityCard> _buildActivityCards() {
    final allPersonsById = {for (final p in persons) p.id: p};

    // Sort activities by category sortOrder.
    final sortedActivities = List<EventActivity>.from(event.activities)
      ..sort((a, b) {
        final oA = categories[a.category.reference]?.sortOrder ?? 0;
        final oB = categories[b.category.reference]?.sortOrder ?? 0;
        return oA.compareTo(oB);
      });

    final cards = <_ShareActivityCard>[];

    for (final activity in sortedActivities) {
      final parentCatRef = activity.category.reference;
      final parentCat = categories[parentCatRef];
      final emoji = parentCat?.displayCharacter ?? '❔';
      final name = parentCat?.name ?? 'Unknown';
      final isSubcat = _isSubcategory(parentCatRef);
      final parentName = isSubcat ? _parentCategoryName(parentCatRef) : null;

      // ── Build per-activity rows (same grouping logic as the event card) ──
      final Map<String, Map<Person, int>> propertyGroups = {};

      for (final participant in activity.participants) {
        final person =
            allPersonsById[participant.participant.reference] ??
            Person(
              date: DateTime.now(),
              name: const Name(given: 'Unknown'),
            );

        if (participant.activityCounts.isEmpty) {
          propertyGroups.putIfAbsent('_no_activity', () => {})[person] = 1;
        } else {
          for (final ac in participant.activityCounts) {
            final key = '${ac.categoryReference.reference}:${ac.activityName}';
            propertyGroups.putIfAbsent(key, () => {})[person] = ac.count;
          }
        }
      }

      final rows = <_ShareActivityRow>[];

      for (final entry in propertyGroups.entries) {
        if (entry.key == '_no_activity') {
          rows.add(_ShareActivityRow.noActivity(entry.value));
          continue;
        }

        final colonIdx = entry.key.indexOf(':');
        final catRef = colonIdx >= 0
            ? entry.key.substring(0, colonIdx)
            : entry.key;
        final actName = colonIdx >= 0
            ? entry.key.substring(colonIdx + 1)
            : entry.key;

        final rowCat = categories[catRef];

        String activityEmoji = '❔';
        String activityDisplayName = actName.isNotEmpty ? actName : 'Unknown';
        bool isRisky = false;

        if (rowCat != null) {
          for (final act in rowCat.activities) {
            if (act.name == actName) {
              activityEmoji = act.displayCharacter;
              activityDisplayName = act.name;
              isRisky = act.stiRisk || act.healthRisk;
              break;
            }
          }
        }

        String? subcategoryLabel;
        if (catRef != parentCatRef) {
          subcategoryLabel = rowCat?.displayCharacter != null
              ? '${rowCat!.displayCharacter}  ${rowCat.name}'
              : rowCat?.name;
        }

        // Sort orders
        int subcatSortOrder = 0;
        int actSortOrder = 0;
        if (rowCat != null) {
          if (catRef != parentCatRef) {
            final parentC = categories[parentCatRef];
            if (parentC != null) {
              final subIdx = parentC.subCategories.indexWhere(
                (r) => r.reference == catRef,
              );
              subcatSortOrder = subIdx >= 0 ? subIdx : rowCat.sortOrder;
            }
          }
          final actIdx = rowCat.activities.indexWhere((a) => a.name == actName);
          if (actIdx >= 0) actSortOrder = rowCat.activities[actIdx].sortOrder;
        }

        rows.add(
          _ShareActivityRow(
            catRef: catRef,
            activityEmoji: activityEmoji,
            activityName: activityDisplayName,
            isRisky: isRisky,
            subcategoryLabel: subcategoryLabel,
            persons: entry.value,
            subcategorySortOrder: subcatSortOrder,
            activitySortOrder: actSortOrder,
          ),
        );
      }

      rows.sort((a, b) {
        if (a.isNoActivity) return -1;
        if (b.isNoActivity) return 1;
        final s = a.subcategorySortOrder.compareTo(b.subcategorySortOrder);
        if (s != 0) return s;
        return a.activitySortOrder.compareTo(b.activitySortOrder);
      });

      cards.add(
        _ShareActivityCard(
          emoji: emoji,
          name: name,
          isSubcategory: isSubcat,
          parentCategoryName: parentName,
          participantCount: activity.participants.length,
          rows: rows,
        ),
      );
    }

    return cards;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activityCards = _buildActivityCards();

    return SizedBox(
      width: cardWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Main content — non-positioned so the Stack sizes itself to
              // this child's intrinsic height.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Date & time ───────────────────────────────────────
                    Text(
                      _formatDate(event.date),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTime(event.date),
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: _dividerColor, height: 1),
                    const SizedBox(height: 12),

                    // ── Activities ────────────────────────────────────────
                    if (activityCards.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No activities recorded',
                          style: TextStyle(
                            color: _textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...activityCards.map(
                            (card) => _ActivityCardWidget(
                              card: card,
                              showActivityNames: showActivityNames,
                              showPartnerNames: showPartnerNames,
                              personDisplayName: _personDisplayName,
                              allPersons: persons,
                            ),
                          ),
                        ],
                      ),

                    // ── Footer watermark ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'made with indulge 💜',
                            style: TextStyle(
                              color: _textSecondary.withOpacity(0.45),
                              fontSize: 9,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Decorative circles rendered on top but Positioned so they
              // don't affect the Stack's intrinsic size.
              Positioned(
                top: -60,
                right: -40,
                child: _Circle(
                  size: 200,
                  color: _accentColor.withOpacity(0.07),
                ),
              ),
              Positioned(
                top: 60,
                left: -50,
                child: _Circle(
                  size: 160,
                  color: _accentColor.withOpacity(0.05),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _ShareActivityCard {
  final String emoji;
  final String name;
  final bool isSubcategory;
  final String? parentCategoryName;
  final int participantCount;
  final List<_ShareActivityRow> rows;

  const _ShareActivityCard({
    required this.emoji,
    required this.name,
    required this.isSubcategory,
    required this.parentCategoryName,
    required this.participantCount,
    required this.rows,
  });
}

class _ShareActivityRow {
  final String catRef;
  final String activityEmoji;
  final String activityName;
  final bool isRisky;
  final String? subcategoryLabel;
  final Map<Person, int> persons;
  final bool isNoActivity;
  final int subcategorySortOrder;
  final int activitySortOrder;

  const _ShareActivityRow({
    required this.catRef,
    required this.activityEmoji,
    required this.activityName,
    required this.isRisky,
    required this.subcategoryLabel,
    required this.persons,
    this.isNoActivity = false,
    this.subcategorySortOrder = 0,
    this.activitySortOrder = 0,
  });

  factory _ShareActivityRow.noActivity(Map<Person, int> persons) =>
      _ShareActivityRow(
        catRef: '',
        activityEmoji: '',
        activityName: '',
        isRisky: false,
        subcategoryLabel: null,
        persons: persons,
        isNoActivity: true,
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ActivityCardWidget extends StatelessWidget {
  final _ShareActivityCard card;
  final bool showActivityNames;
  final bool showPartnerNames;
  final String Function(Person, int) personDisplayName;
  final List<Person> allPersons;

  const _ActivityCardWidget({
    required this.card,
    required this.showActivityNames,
    required this.showPartnerNames,
    required this.personDisplayName,
    required this.allPersons,
  });

  @override
  Widget build(BuildContext context) {
    final noActivityRows = card.rows.where((r) => r.isNoActivity).toList();
    final activityRows = card.rows.where((r) => !r.isNoActivity).toList();

    // Group by subcategoryLabel (null = direct parent activity).
    final grouped = <String?, List<_ShareActivityRow>>{};
    for (final row in activityRows) {
      grouped.putIfAbsent(row.subcategoryLabel, () => []).add(row);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SexualEventShareCard._surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SexualEventShareCard._accentColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category header ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showActivityNames)
                        Text(
                          card.name,
                          style: const TextStyle(
                            color: SexualEventShareCard._textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      if (showActivityNames &&
                          card.isSubcategory &&
                          card.parentCategoryName != null)
                        Text(
                          'in ${card.parentCategoryName}',
                          style: const TextStyle(
                            color: SexualEventShareCard._textSecondary,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        '${card.participantCount} '
                        '${card.participantCount == 1 ? 'participant' : 'participants'}',
                        style: const TextStyle(
                          color: SexualEventShareCard._textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (card.rows.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(
                color: SexualEventShareCard._dividerColor,
                height: 1,
              ),
              const SizedBox(height: 8),

              // ── No-activity participants ──────────────────────────────
              for (final row in noActivityRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: row.persons.entries.map((e) {
                      final idx = allPersons.indexOf(e.key);
                      return _MiniAvatar(
                        person: e.key,
                        displayName: personDisplayName(
                          e.key,
                          idx < 0 ? 0 : idx,
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // ── Grouped activity rows ─────────────────────────────────
              ...grouped.entries.map((entry) {
                final subcatLabel = entry.key;
                final rows = entry.value;

                if (subcatLabel != null) {
                  // Subcategory block
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: SexualEventShareCard._subcategoryBg,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: SexualEventShareCard._subcategoryBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subcategory header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: SexualEventShareCard._accentColor
                                .withOpacity(0.15),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                          child: showActivityNames
                              ? Text(
                                  subcatLabel,
                                  style: const TextStyle(
                                    color: SexualEventShareCard._textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: rows
                                .map(
                                  (r) => _ActivityRowWidget(
                                    row: r,
                                    showActivityNames: showActivityNames,
                                    personDisplayName: personDisplayName,
                                    allPersons: allPersons,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Flat rows (no subcategory grouping)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows
                        .map(
                          (r) => _ActivityRowWidget(
                            row: r,
                            showActivityNames: showActivityNames,
                            personDisplayName: personDisplayName,
                            allPersons: allPersons,
                          ),
                        )
                        .toList(),
                  );
                }
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRowWidget extends StatelessWidget {
  final _ShareActivityRow row;
  final bool showActivityNames;
  final String Function(Person, int) personDisplayName;
  final List<Person> allPersons;

  const _ActivityRowWidget({
    required this.row,
    required this.showActivityNames,
    required this.personDisplayName,
    required this.allPersons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(row.activityEmoji, style: const TextStyle(fontSize: 14)),
              if (showActivityNames) ...[
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    row.activityName,
                    style: const TextStyle(
                      color: SexualEventShareCard._textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (row.isRisky)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 12,
                    color: Color(0xFFFFB74D),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Wrap(
              spacing: 5,
              runSpacing: 4,
              children: row.persons.entries.map((e) {
                final idx = allPersons.indexOf(e.key);
                return _MiniAvatar(
                  person: e.key,
                  displayName: personDisplayName(e.key, idx < 0 ? 0 : idx),
                  count: e.value > 1 ? e.value : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final Person person;
  final String displayName;
  final int? count;

  const _MiniAvatar({
    required this.person,
    required this.displayName,
    this.count,
  });

  Uint8List? _decodeAvatar() {
    final raw = person.imageBytes;
    if (raw == null || raw.isEmpty) return null;
    try {
      final bytes = base64Decode(raw);
      return bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  String _initials() {
    final nick = person.name.nickname ?? '';
    final given = person.name.given ?? '';
    final family = person.name.family ?? '';
    if (nick.isNotEmpty) return nick[0].toUpperCase();
    if (given.isNotEmpty && family.isNotEmpty) {
      return '${given[0]}${family[0]}'.toUpperCase();
    }
    if (given.isNotEmpty) return given[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final avatarBytes = _decodeAvatar();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: SexualEventShareCard._accentColor.withOpacity(
                0.35,
              ),
              backgroundImage: avatarBytes != null
                  ? MemoryImage(avatarBytes)
                  : null,
              child: avatarBytes == null
                  ? Text(
                      _initials(),
                      style: const TextStyle(
                        color: SexualEventShareCard._textPrimary,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (count != null)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: SexualEventShareCard._accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SexualEventShareCard._surfaceColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: SexualEventShareCard._textPrimary,
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 5),
        Text(
          displayName,
          style: const TextStyle(
            color: SexualEventShareCard._textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
