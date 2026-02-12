import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import '../common/page_title.dart';
import 'event_averages_section.dart';
import 'co_occurrence_section.dart';
import 'activity_type_distribution.dart';
import 'properties_by_activity_section.dart';
import 'category_trends_chart.dart';
import 'property_trends_chart.dart';

class ActivityBreakdownPage extends StatelessWidget {
  final AnalysisData data;
  final AnalysisEventType? selectedType;
  final ValueChanged<AnalysisEventType?> onTypeChanged;

  const ActivityBreakdownPage({
    super.key,
    required this.data,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const PageTitle(
          title: 'Activity Breakdown',
          icon: Icons.list_alt,
          subtitle: 'Categories, activities, and averages',
        ),
        _buildFilterChips(context),
        const SizedBox(height: 16),
        EventAveragesSection(data: data, filterType: selectedType),
        CoOccurrenceSection(data: data, filterType: selectedType),
        const SizedBox(height: 16),
        ActivityTypeDistribution(data: data, filterType: selectedType),
        PropertiesByActivitySection(data: data, filterType: selectedType),
        CategoryTrendsChart(
          data: data,
          filterType: selectedType,
          showTypeFilter: false,
        ),
        PropertyTrendsChart(
          data: data,
          filterType: selectedType,
          showTypeFilter: false,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(context, 'Total', null),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Solo', AnalysisEventType.solo),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Couple', AnalysisEventType.couple),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Group', AnalysisEventType.group),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    AnalysisEventType? type,
  ) {
    final isSelected = selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onTypeChanged(type);
        }
      },
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
