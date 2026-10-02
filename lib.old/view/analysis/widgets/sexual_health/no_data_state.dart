import 'package:flutter/material.dart';
import '../common/page_title.dart';

/// Widget shown when there's no STI test data available.
class NoDataState extends StatelessWidget {
  const NoDataState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const PageTitle(
          title: 'Sexual Health',
          icon: Icons.medical_services,
          subtitle:
              'A reflection of your sexual habits and their impacts on your health',
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No STI Test Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'You haven\'t logged any STI tests yet. Add a clinical event to start tracking your sexual health stats.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
