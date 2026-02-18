import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import '../../models/sexual_health_analysis_data.dart';

/// Widget showing positive test results and partner notification info.
class PositiveTestCard extends StatelessWidget {
  final SexualHealthAnalysisData data;

  const PositiveTestCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (!data.testedPositive) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildPositiveTestWarning(context),
        const SizedBox(height: 16),
        _buildPartnersToNotifyCard(context),
      ],
    );
  }

  Widget _buildPositiveTestWarning(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 24, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Positive Test Result',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You tested positive for the following on ${_formatDate(data.periodStartDate)}:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.positiveTests.map((test) {
                return Chip(
                  label: Text(
                    _formatTestType(test.testType),
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                  backgroundColor: Colors.red.shade100,
                  side: BorderSide(color: Colors.red.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'It\'s important to inform recent sexual partners so they can get tested.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnersToNotifyCard(BuildContext context) {
    if (data.partnersToNotify.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Partners to Notify',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No sexual activity recorded in this period.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 20,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Partners to Notify',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These partners should be informed about your positive test result:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...data.partnersToNotify.map(
              (partner) => _buildPartnerNotificationTile(context, partner),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerNotificationTile(
    BuildContext context,
    PartnerNotificationInfo partner,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: partner.isAnonymous
                    ? Colors.orange.shade200
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  partner.isAnonymous ? Icons.person_outline : Icons.person,
                  size: 18,
                  color: partner.isAnonymous
                      ? Colors.orange.shade700
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${partner.eventCount} event${partner.eventCount == 1 ? '' : 's'} in this period',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (partner.lastEventDate != null)
                Text(
                  _formatDate(partner.lastEventDate!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (partner.activityTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: partner.activityTypes.take(3).map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTestType(TestType type) {
    switch (type) {
      case TestType.chlamydia:
        return 'Chlamydia';
      case TestType.gonorrhea:
        return 'Gonorrhea';
      case TestType.hiv:
        return 'HIV';
      case TestType.syphilis:
        return 'Syphilis';
      case TestType.trichomonas:
        return 'Trichomonas';
      case TestType.hepatitis:
        return 'Hepatitis';
      case TestType.other:
        return 'Other';
    }
  }
}
