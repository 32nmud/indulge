import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../utils/analysis_colors.dart';
import 'event_averages_section.dart';
import 'co_occurrence_section.dart';
import 'activity_type_distribution.dart';
import 'properties_by_activity_section.dart';
import 'category_trends_chart.dart';
import 'property_trends_chart.dart';

class ActivityBreakdownPage extends StatefulWidget {
  final AnalysisData data;

  const ActivityBreakdownPage({super.key, required this.data});

  @override
  State<ActivityBreakdownPage> createState() => _ActivityBreakdownPageState();
}

class _ActivityBreakdownPageState extends State<ActivityBreakdownPage> {
  AnalysisEventType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildPageTitle(
          context,
          'Activity Breakdown',
          Icons.list_alt,
          'Categories, activities, and averages',
        ),
        _buildFilterChips(),
        const SizedBox(height: 16),
        EventAveragesSection(data: widget.data, filterType: _selectedType),
        CoOccurrenceSection(data: widget.data, filterType: _selectedType),
        const SizedBox(height: 16),
        ActivityTypeDistribution(data: widget.data, filterType: _selectedType),
        PropertiesByActivitySection(
          data: widget.data,
          filterType: _selectedType,
        ),
        CategoryTrendsChart(
          data: widget.data,
          filterType: _selectedType,
          showTypeFilter: false,
        ),
        PropertyTrendsChart(
          data: widget.data,
          filterType: _selectedType,
          showTypeFilter: false,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Total', null),
          const SizedBox(width: 8),
          _buildFilterChip('Solo', AnalysisEventType.solo),
          const SizedBox(width: 8),
          _buildFilterChip('Couple', AnalysisEventType.couple),
          const SizedBox(width: 8),
          _buildFilterChip('Group', AnalysisEventType.group),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AnalysisEventType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
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

  Widget _buildPageTitle(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
