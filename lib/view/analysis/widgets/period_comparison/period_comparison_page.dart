import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import '../common/page_title.dart';
import 'period_comparison_section.dart';

class PeriodComparisonPage extends StatelessWidget {
  final AnalysisData data;
  final PeriodPreset selectedPreset;
  final DateTimeRange? customFirstPeriod;
  final DateTimeRange? customSecondPeriod;
  final ValueChanged<PeriodPreset> onPresetChanged;
  final ValueChanged<DateTimeRange?> onCustomFirstPeriodChanged;
  final ValueChanged<DateTimeRange?> onCustomSecondPeriodChanged;

  const PeriodComparisonPage({
    super.key,
    required this.data,
    required this.selectedPreset,
    required this.onPresetChanged,
    this.customFirstPeriod,
    this.customSecondPeriod,
    required this.onCustomFirstPeriodChanged,
    required this.onCustomSecondPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const PageTitle(
          title: 'Period Comparison',
          icon: Icons.compare_arrows,
          subtitle: 'Compare any two date ranges',
        ),
        PeriodComparisonSection(
          data: data,
          selectedPreset: selectedPreset,
          onPresetChanged: onPresetChanged,
          customFirstPeriod: customFirstPeriod,
          customSecondPeriod: customSecondPeriod,
          onCustomFirstPeriodChanged: onCustomFirstPeriodChanged,
          onCustomSecondPeriodChanged: onCustomSecondPeriodChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
