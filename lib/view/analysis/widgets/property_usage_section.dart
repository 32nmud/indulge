import 'package:flutter/material.dart';
import '../models/analysis_data.dart';

class PropertyUsageSection extends StatelessWidget {
  final AnalysisData data;

  const PropertyUsageSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.propertyCountsTotal.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort properties by count and take top 15
    final sortedProperties = data.propertyCountsTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProperties = sortedProperties.take(15).toList();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Used Properties',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Top properties across all activities',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...topProperties.asMap().entries.map((entry) {
              final index = entry.key;
              final propertyEntry = entry.value;
              final property = data.properties[propertyEntry.key];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _getColorForRank(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Property name with risky indicator
                    Expanded(
                      child: Row(
                        children: [
                          if (property?.isRisky ?? false)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.red[400],
                              ),
                            ),
                          Expanded(
                            child: Text(
                              property?.name ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Count with badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getColorForRank(index).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${propertyEntry.value}×',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getColorForRank(index),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getColorForRank(int index) {
    if (index == 0) return Colors.amber[700]!; // Gold
    if (index == 1) return Colors.grey[600]!; // Silver
    if (index == 2) return Colors.orange[800]!; // Bronze
    return Colors.blue[700]!; // Default
  }
}
