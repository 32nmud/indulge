import 'package:flutter/material.dart';
import '../models/analysis_data.dart';

class RiskyActivityTracker extends StatelessWidget {
  final AnalysisData data;

  const RiskyActivityTracker({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final riskyPercentage = data.totalActivities > 0
        ? (data.riskyActivityCount / data.totalActivities * 100).round()
        : 0;
    final safePercentage = 100 - riskyPercentage;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety Tracker',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Risky vs safe activities',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (safePercentage > 0)
                      Flexible(
                        flex: safePercentage,
                        child: Container(
                          color: Colors.green,
                          alignment: Alignment.center,
                          child: safePercentage >= 15
                              ? Text(
                                  '$safePercentage%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    if (riskyPercentage > 0)
                      Flexible(
                        flex: riskyPercentage,
                        child: Container(
                          color: Colors.red,
                          alignment: Alignment.center,
                          child: riskyPercentage >= 15
                              ? Text(
                                  '$riskyPercentage%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildLegendItem(
                    context,
                    icon: Icons.shield_outlined,
                    label: 'Safe',
                    count: data.safeActivityCount,
                    percentage: safePercentage,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLegendItem(
                    context,
                    icon: Icons.warning_amber_rounded,
                    label: 'Risky',
                    count: data.riskyActivityCount,
                    percentage: riskyPercentage,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days since last risky activity
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: data.daysSinceLastRiskyActivity >= 30
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: data.daysSinceLastRiskyActivity >= 30
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    data.daysSinceLastRiskyActivity >= 30
                        ? Icons.celebration
                        : Icons.calendar_today,
                    color: data.daysSinceLastRiskyActivity >= 30
                        ? Colors.green[700]
                        : Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.daysSinceLastRiskyActivity == -1
                              ? 'No risky activities recorded'
                              : data.daysSinceLastRiskyActivity == 0
                              ? 'Risky activity today'
                              : 'Days since last risky activity',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (data.daysSinceLastRiskyActivity > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${data.daysSinceLastRiskyActivity} day${data.daysSinceLastRiskyActivity != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: data.daysSinceLastRiskyActivity >= 30
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (data.daysSinceLastRiskyActivity >= 30)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '30+ days!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required int percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
