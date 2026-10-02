import 'package:flutter/material.dart';
import '../../models/sexual_health_analysis_data.dart';
import '../common/page_title.dart';
import 'risk_assessment_card.dart';
import 'period_selector_card.dart';
import 'period_info_card.dart';
import 'partner_list_section.dart';
import 'positive_test_card.dart';
import 'category_breakdown_section.dart';
import 'no_data_state.dart';
import 'package:intl/intl.dart';

// ── Overdue banner ────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  final SexualHealthAnalysisData data;
  const _OverdueBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final daysSinceTest = DateTime.now()
        .difference(data.periodStartDate)
        .inDays;
    final fmt = DateFormat('MMM d, yyyy');
    final lastTestFormatted = fmt.format(data.periodStartDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STI Test Overdue',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last tested $lastTestFormatted — '
                  '$daysSinceTest ${daysSinceTest == 1 ? 'day' : 'days'} ago. '
                  'CDC guidelines recommend testing every 3 months.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

        // 1. Test date selector
        PeriodSelectorCard(
          data: data,
          onTestIndexChanged: widget.onTestIndexChanged,
        ),
        const SizedBox(height: 8),

        // 2. Positive test alert (if applicable)
        PositiveTestCard(data: data),

        // 3. STI test overdue alert (if applicable)
        if (data.isMostRecent && data.isOverdueForTesting) ...[
          const SizedBox(height: 8),
          _OverdueBanner(data: data),
        ],

        const SizedBox(height: 8),

        // 4. Period info
        PeriodInfoCard(data: data),
        const SizedBox(height: 16),

        // 5. Risk assessment
        RiskAssessmentCard(data: data),
        const SizedBox(height: 16),

        // 6. Partners in period
        PartnerListSection(data: data),
        const SizedBox(height: 16),

        // 7. STI and health risk activities breakdown
        CategoryBreakdownSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }
}
