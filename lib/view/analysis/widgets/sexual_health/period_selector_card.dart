import 'package:flutter/material.dart';
import '../../models/since_last_test_data.dart';

/// Widget for selecting which test period to view.
class PeriodSelectorCard extends StatelessWidget {
  final SinceLastTestData data;
  final void Function(int testIndex)? onTestIndexChanged;

  const PeriodSelectorCard({
    super.key,
    required this.data,
    this.onTestIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (data.testDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: data.selectedTestIndex,
                  isExpanded: true,
                  items: List.generate(
                    data.testDates.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(_getTestPeriodLabel(index)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null && onTestIndexChanged != null) {
                      onTestIndexChanged!(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTestPeriodLabel(int index) {
    if (index == 0) return 'Most Recent Test';
    if (index == 1) return '2nd Most Recent Test';
    return '${index + 1}th Most Recent Test';
  }
}
