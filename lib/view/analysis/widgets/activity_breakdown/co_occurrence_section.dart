import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';

class CoOccurrenceSection extends StatefulWidget {
  final AnalysisData data;
  final AnalysisEventType? filterType;

  const CoOccurrenceSection({super.key, required this.data, this.filterType});

  @override
  State<CoOccurrenceSection> createState() => _CoOccurrenceSectionState();
}

class _CoOccurrenceSectionState extends State<CoOccurrenceSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryPairs = _getPairs(true);
    final activityPairs = _getPairs(false);

    if (categoryPairs.isEmpty && activityPairs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Combinations',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Categories'),
              Tab(text: 'Activities'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _tabController.index == 0
            ? _buildPairList(categoryPairs, Colors.teal)
            : _buildPairList(activityPairs, Colors.orange),
      ],
    );
  }

  List<CoOccurrencePair> _getPairs(bool categories) {
    if (widget.filterType == null) {
      return categories
          ? widget.data.topCategoryPairs
          : widget.data.topActivityPairs;
    }

    final events = widget.data.eventsByType[widget.filterType!] ?? [];
    final pairCounts = <String, int>{};

    for (final event in events) {
      final ids = <String>{};
      if (categories) {
        for (final activity in event.activities) {
          ids.add(activity.category.reference);
        }
      } else {
        for (final activity in event.activities) {
          for (final participant in activity.participants) {
            for (final count in participant.activityCounts) {
              ids.add(count.activityReference.reference);
            }
          }
        }
      }

      final idList = ids.toList()..sort();
      for (int i = 0; i < idList.length; i++) {
        for (int j = i + 1; j < idList.length; j++) {
          final key = '${idList[i]}|${idList[j]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    return pairCounts.entries.map((e) {
      final parts = e.key.split('|');
      final id1 = parts[0];
      final id2 = parts[1];
      final name1 = categories
          ? (widget.data.activityCategories[id1]?.name ?? 'Unknown')
          : (widget.data.sexualActivities[id1]?.name ?? 'Unknown');
      final name2 = categories
          ? (widget.data.activityCategories[id2]?.name ?? 'Unknown')
          : (widget.data.sexualActivities[id2]?.name ?? 'Unknown');

      return CoOccurrencePair(
        id1: id1,
        id2: id2,
        name1: name1,
        name2: name2,
        count: e.value,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  Widget _buildPairList(List<CoOccurrencePair> pairs, Color color) {
    if (pairs.isEmpty) {
      return const Center(child: Text('No combinations found yet.'));
    }

    // Limit to top 10
    final displayPairs = pairs.take(10).toList();
    final maxCount = displayPairs.first.count;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayPairs.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final pair = displayPairs[index];
        final ratio = pair.count / maxCount;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: pair.name1,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' + ',
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          TextSpan(
                            text: pair.name2,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${pair.count}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
