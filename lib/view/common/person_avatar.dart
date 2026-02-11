import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class PersonAvatar extends StatelessWidget {
  final Person person;
  final double radius;
  final int? count;
  final bool showName;
  final VoidCallback? onTap;
  final bool isSelected;

  const PersonAvatar({
    super.key,
    required this.person,
    this.radius = 20,
    this.count,
    this.showName = false,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelf = person.isSelf;

    Uint8List? imageBytes;
    if (person.imageBytes != null && person.imageBytes!.isNotEmpty) {
      try {
        final decoded = base64Decode(person.imageBytes!);
        if (decoded.isNotEmpty) {
          imageBytes = decoded;
        }
      } catch (e) {
        // ignore invalid base64
      }
    }

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: isSelected
          ? colorScheme.primary
          : isSelf
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
      child: imageBytes == null
          ? isSelf
                ? Icon(
                    Icons.account_circle,
                    size: radius * 1.5,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimaryContainer,
                  )
                : Text(
                    _getInitials(person),
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  )
          : null,
    );

    Widget content = avatar;

    if (count != null && count! > 1) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: colorScheme.onSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (showName) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const SizedBox(height: 4),
          Text(
            person.name.nickname ?? person.name.given ?? 'Unknown',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : null,
              color: isSelected ? colorScheme.primary : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      );
    }

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: content,
      );
    }

    return content;
  }

  String _getInitials(Person person) {
    final given = person.name.given ?? '';
    final family = person.name.family ?? '';
    final nickname = person.name.nickname ?? '';

    if (nickname.isNotEmpty) {
      return nickname.substring(0, 1).toUpperCase();
    }

    if (given.isNotEmpty && family.isNotEmpty) {
      return '${given[0]}${family[0]}'.toUpperCase();
    }

    if (given.isNotEmpty) {
      return given[0].toUpperCase();
    }

    return '?';
  }
}
