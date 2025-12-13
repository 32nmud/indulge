import 'package:flutter/material.dart';
import 'package:indulge/data/models/person/person.dart';
import 'package:indulge/view/event_editor/add_item_card.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models/sexual_activity/sexual_activity.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'participant_card.dart';

typedef RemovedItemBuilder<T> =
    Widget Function(T item, BuildContext context, Animation<double> animation);

class AnimatedEventParticipantList extends StatefulWidget {
  const AnimatedEventParticipantList({super.key});

  @override
  State<AnimatedEventParticipantList> createState() =>
      _AnimatedEventParticipantListState();
}

class _AnimatedEventParticipantListState
    extends State<AnimatedEventParticipantList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<Person> _list;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SexualEventsProvider>();
    _list = ListModel<Person>(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: provider.state.selectedEventParticipants ?? [],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SexualEventsProvider>();
    _list.syncWith(provider.state.selectedEventParticipants ?? []);
  }

  Widget _buildItem(
    int index,
    BuildContext context,
    Animation<double> animation,
  ) {
    final provider = context.read<SexualEventsProvider>();
    return SizeTransition(
      sizeFactor: animation,
      child: ParticipantCard(
        participant: _list[index],
        eventId: provider.state.selectedEvent!.id,
      ),
    );
  }

  Widget _buildRemovedItem(
    Person participant,
    BuildContext context,
    Animation<double> animation,
  ) {
    final provider = context.read<SexualEventsProvider>();
    return SizeTransition(
      sizeFactor: animation,
      child: ParticipantCard(
        participant: participant,
        eventId: provider.state.selectedEvent!.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SexualEventsProvider>();

    return AnimatedList(
      shrinkWrap: true,
      key: _listKey,
      initialItemCount: _list.length,
      itemBuilder: (context, index, animation) =>
          _buildItem(index, context, animation),
    );
  }
}

/// A lightweight wrapper that keeps a Dart [List] in sync with an [AnimatedList].
class ListModel<E> {
  ListModel({
    required this.listKey,
    required this.removedItemBuilder,
    Iterable<E>? initialItems,
  }) : _items = List<E>.from(initialItems ?? <E>[]);

  final GlobalKey<AnimatedListState> listKey;
  final RemovedItemBuilder<E> removedItemBuilder;
  final List<E> _items;

  AnimatedListState? get _animatedList => listKey.currentState;

  int get length => _items.length;
  E operator [](int index) => _items[index];

  /// Replaces the current items with [newItems], animating removals and insertions.
  void syncWith(Iterable<E> newItems) {
    for (int i = _items.length - 1; i >= 0; i--) {
      E removed = _items[i];
      _animatedList?.removeItem(
        i,
        (context, animation) => removedItemBuilder(removed, context, animation),
      );
    }
    _items.clear();

    for (int i = 0; i < newItems.length; i++) {
      _items.add(newItems.elementAt(i));
      _animatedList?.insertItem(i);
    }
  }
}
