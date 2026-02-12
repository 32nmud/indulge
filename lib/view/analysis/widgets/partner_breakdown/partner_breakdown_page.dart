import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import '../common/page_title.dart';
import 'top_partners_section.dart';
import 'property_partner_section.dart';

class PartnerBreakdownPage extends StatelessWidget {
  final AnalysisData data;

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
        PropertyPartnerSection(data: data),
        const SizedBox(height: 16),
      ],
    );
  }
}
