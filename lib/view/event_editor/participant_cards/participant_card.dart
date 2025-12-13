import 'package:flutter/material.dart';
import 'package:indulge/data/models/sexual_activity/sexual_activity.dart';
import 'package:indulge/data/models/person/person.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:provider/provider.dart';

class ParticipantCard extends StatefulWidget {
  final Person participant;
  final String eventId;
  const ParticipantCard({
    super.key,
    required this.participant,
    required this.eventId,
  });

  @override
  State<ParticipantCard> createState() => _ParticipantCardState();
}

class _ParticipantCardState extends State<ParticipantCard> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  Widget _previewIcon() {
    return Padding(
      padding: EdgeInsetsGeometry.directional(end: 10),
      child: Icon(Icons.person),
    );
  }

  Widget _editButton(BuildContext context) {
    // TODO: Make this button give a popup if there's an error
    SexualEventsProvider provider = context.read<SexualEventsProvider>();
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () {
            provider.removeParticipant(widget.participant);
          },
          child: const Text('Remove'),
        ),
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

  Widget _participantCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _previewIcon(),
            Expanded(child: Text(widget.participant.name.given ?? "Unknown")),
            _editButton(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _participantCard(context);
  }
}
