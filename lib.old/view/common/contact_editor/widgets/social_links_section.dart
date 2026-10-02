import 'package:flutter/material.dart';

class SocialLinksSection extends StatefulWidget {
  final List<String> initialLinks;
  final ValueChanged<List<String>> onLinksChanged;

  const SocialLinksSection({
    super.key,
    required this.initialLinks,
    required this.onLinksChanged,
  });

  @override
  State<SocialLinksSection> createState() => _SocialLinksSectionState();
}

class _SocialLinksSectionState extends State<SocialLinksSection> {
  late List<String> _links;
  late TextEditingController _newLinkController;

  @override
  void initState() {
    super.initState();
    _links = List.from(widget.initialLinks);
    _newLinkController = TextEditingController();
  }

  @override
  void dispose() {
    _newLinkController.dispose();
    super.dispose();
  }

  void _addLink() {
    final text = _newLinkController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _links.add(text);
        _newLinkController.clear();
      });
      widget.onLinksChanged(_links);
    }
  }

  void _removeLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
    widget.onLinksChanged(_links);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Links',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._links.asMap().entries.map((entry) {
              final index = entry.key;
              final link = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _removeLink(index),
                      tooltip: 'Remove link',
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Add Link',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _addLink(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addLink,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add link',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
