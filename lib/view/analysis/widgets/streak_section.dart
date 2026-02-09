import 'package:flutter/material.dart';
import '../models/analysis_data.dart';

class StreakSection extends StatelessWidget {
  final AnalysisData data;

  const StreakSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streaks & Activity Goals',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your consistency and progress toward event milestones',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            // Current Streak
            _buildStreakItem(
              context,
              icon: Icons.local_fire_department,
              label: 'Current Streak',
              value: data.currentStreak,
              unit: 'day${data.currentStreak != 1 ? 's' : ''}',
              color: Colors.orange,
              subtitle: _getStreakMessage(data.currentStreak),
            ),
            const SizedBox(height: 12),
            // Longest Streak
            _buildStreakItem(
              context,
              icon: Icons.emoji_events,
              label: 'Longest Streak',
              value: data.longestStreak,
              unit: 'day${data.longestStreak != 1 ? 's' : ''}',
              color: Colors.amber[700]!,
              subtitle: data.longestStreak == data.currentStreak
                  ? 'You\'re on your longest streak!'
                  : 'Keep going to beat your record!',
            ),
            const SizedBox(height: 12),
            // Days since last activity
            _buildStreakItem(
              context,
              icon: Icons.calendar_today,
              label: 'Last Activity',
              value: data.daysSinceLastActivity,
              unit: data.daysSinceLastActivity == 0
                  ? 'today'
                  : data.daysSinceLastActivity == 1
                  ? 'day ago'
                  : 'days ago',
              color: data.daysSinceLastActivity <= 3
                  ? Colors.green
                  : data.daysSinceLastActivity <= 7
                  ? Colors.blue
                  : Colors.grey,
              subtitle: _getLastActivityMessage(data.daysSinceLastActivity),
            ),
            const SizedBox(height: 16),
            // Milestone progress
            _buildMilestoneProgress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required String unit,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress(BuildContext context) {
    final milestones = [5, 10, 25, 50, 100, 250, 500, 1000];
    final nextMilestone = milestones.firstWhere(
      (m) => m > data.totalEvents,
      orElse: () => data.totalEvents + 100,
    );
    final previousMilestone = data.totalEvents >= 5
        ? milestones.lastWhere((m) => m <= data.totalEvents, orElse: () => 0)
        : 0;

    final progress = previousMilestone == 0
        ? data.totalEvents / nextMilestone
        : (data.totalEvents - previousMilestone) /
              (nextMilestone - previousMilestone);

    final remaining = nextMilestone - data.totalEvents;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.purple[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Next Event Milestone: ${_getMilestoneLabel(nextMilestone)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$nextMilestone events',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining more event${remaining != 1 ? 's' : ''} to go!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          if (data.totalEvents >= 5) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: milestones
                  .where((m) => m <= data.totalEvents)
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 10,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$m',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return 'Start a new streak today!';
    if (streak < 3) return 'Just getting started!';
    if (streak < 7) return 'Keep it up!';
    if (streak < 14) return 'You\'re on a roll!';
    if (streak < 30) return 'Impressive consistency!';
    if (streak < 60) return 'Amazing dedication!';
    return 'Legendary streak!';
  }

  String _getLastActivityMessage(int days) {
    if (days == 0) return 'Activity logged today';
    if (days == 1) return 'Yesterday';
    if (days <= 3) return 'Recent activity';
    if (days <= 7) return 'This week';
    if (days <= 14) return 'Last two weeks';
    if (days <= 30) return 'This month';
    return 'It\'s been a while';
  }

  String _getMilestoneLabel(int milestone) {
    if (milestone <= 5) return 'First Five!';
    if (milestone <= 10) return 'Perfect Ten';
    if (milestone <= 25) return 'Quarter Century';
    if (milestone <= 50) return 'Half Hundred';
    if (milestone <= 100) return 'The Century';
    if (milestone <= 250) return 'Quarter Thousand';
    if (milestone <= 500) return 'Five Hundred Club';
    if (milestone <= 1000) return 'The Thousand';
    return 'Legendary';
  }
}
