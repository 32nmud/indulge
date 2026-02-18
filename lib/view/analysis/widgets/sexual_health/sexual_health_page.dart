import 'package:flutter/material.dart';
import '../../models/sexual_health_analysis_data.dart';
import '../common/page_title.dart';
import 'risk_assessment_card.dart';
import 'period_selector_card.dart';
import 'period_info_card.dart';
import 'partner_list_section.dart';
import 'positive_test_card.dart';
import 'activity_breakdown_section.dart';
import 'category_breakdown_section.dart';
import 'no_data_state.dart';

/// Page widget displaying sexual health statistics between STI tests.
class SexualHealthPage extends StatefulWidget {
  final SexualHealthAnalysisData data;
  final void Function(int testIndex)? onTestIndexChanged;

  const SexualHealthPage({
    super.key,
    required this.data,
    this.onTestIndexChanged,
  });

  @override
  State<SexualHealthPage> createState() => _SexualHealthPageState();
}

class _SexualHealthPageState extends State<SexualHealthPage> {
  SexualHealthAnalysisData get data => widget.data;

  @override
  Widget build(BuildContext context) {
    if (!data.hasValidData) {
      return const NoDataState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const PageTitle(
          title: 'Sexual Health',
          icon: Icons.medical_services,
          subtitle:
              'A reflection of your sexual habits and their impacts on your health',
        ),

        // Test period selector dropdown
        PeriodSelectorCard(
          data: data,
          onTestIndexChanged: widget.onTestIndexChanged,
        ),
        const SizedBox(height: 16),

        // Risk assessment (at top)
        RiskAssessmentCard(data: data),
        const SizedBox(height: 16),

        // Period info
        PeriodInfoCard(data: data),
        const SizedBox(height: 16),

        // Partner list
        PartnerListSection(data: data),
        const SizedBox(height: 16),

        // Category breakdown (risky activities)
        CategoryBreakdownSection(data: data),
        const SizedBox(height: 16),

        // Positive test warning and partners to notify
        PositiveTestCard(data: data),
        const SizedBox(height: 16),

        // Activity breakdown
        if (data.eventCountInPeriod > 0) ...[
          ActivityBreakdownSection(data: data),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
