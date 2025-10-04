import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_activity.dart';
import 'package:indulge/provider/event_provider.dart';
import 'package:provider/provider.dart';

class ActivityCard extends StatefulWidget {
  final SexualActivity activity;
  const ActivityCard({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  Widget _previewIcon() {
    return Padding(
        padding: EdgeInsetsGeometry.directional(end: 10),
        child: Icon(Icons.monitor_heart));
  }

  Widget _editButton(BuildContext context) {
    EventsProvider provider = context.read<EventsProvider>();
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
            onPressed: () {
              provider.removeActivityFromEdit(super.widget.activity.id);
            },
            child: const Text('Remove')),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          focusNode: _buttonFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }

  Widget _activityCard(BuildContext context) {
    bool isRisky = super.widget.activity.isRisky;
    return Card(
        color: isRisky ? Colors.redAccent : Theme.of(context).cardColor,
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _previewIcon(),
                Expanded(child: Text(super.widget.activity.name)),
                _editButton(context),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return _activityCard(context);
  }
}
