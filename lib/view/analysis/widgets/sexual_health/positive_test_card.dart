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

    return _buildPositiveTestAlert(context);
  }

  Widget _buildPositiveTestAlert(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 22,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Positive Test Result',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'You tested positive for the following on ${_formatDate(data.periodStartDate)}:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: data.positiveTests.map((test) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatTestType(test.testType),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onError,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Inform recent sexual partners so they can get tested.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ],
        ),
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
