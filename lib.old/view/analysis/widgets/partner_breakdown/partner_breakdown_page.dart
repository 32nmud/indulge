import 'package:flutter/material.dart';
import '../common/page_title.dart';
import 'top_partners_section.dart';
import 'partner_activity_diversity_section.dart';
import '../../models/partner_breakdown_data.dart';

class PartnerBreakdownPage extends StatelessWidget {
  final PartnerBreakdownData data;

  const PartnerBreakdownPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const PageTitle(
          title: 'Partner Breakdown',
          icon: Icons.people,
          subtitle: 'Top partners and diversity stats',
        ),
        TopPartnersSection(data: data),
        PartnerActivityDiversitySection(
          data: data,
          showActionable: true,
          title: 'Partner Diversity — Activities',
          subtitle: 'Unique partners per activity — grouped by category',
          icon: Icons.sports_martial_arts,
        ),
        PartnerActivityDiversitySection(
          data: data,
          showActionable: false,
          title: 'Partner Diversity — Gear & Items',
          subtitle: 'Unique partners per item — grouped by category',
          icon: Icons.hardware,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
