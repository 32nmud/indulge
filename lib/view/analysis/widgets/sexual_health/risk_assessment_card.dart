import 'package:flutter/material.dart';
import '../../models/since_last_test_data.dart';

/// Widget showing risk assessment for the sexual health period.
class RiskAssessmentCard extends StatelessWidget {
  final SinceLastTestData data;

  const RiskAssessmentCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Color riskColor;
    IconData riskIcon;

    switch (data.riskLevel) {
      case 'Low':
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
        break;
      case 'Moderate':
        riskColor = Colors.orange;
        riskIcon = Icons.info;
        break;
      case 'High':
        riskColor = Colors.red;
        riskIcon = Icons.warning;
        break;
      case 'Very High':
        riskColor = Colors.red.shade900;
        riskIcon = Icons.dangerous;
        break;
      default:
        riskColor = Colors.grey;
        riskIcon = Icons.help;
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
                  Icons.shield,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Risk Assessment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(riskIcon, color: riskColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            data.riskLevel,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.riskDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: data.riskScore / 100,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                      Text(
                        '${data.riskScore}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  context,
                  '${data.riskyActivityCountInPeriod}',
                  'Risky Activities',
                  Colors.red.shade100,
                  Colors.red.shade900,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  '${data.safeActivityCountInPeriod}',
                  'Safe Activities',
                  Colors.green.shade100,
                  Colors.green.shade900,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
