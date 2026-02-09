import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models/sexual_event/sexual_event.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/common/event_card/event_card.dart';

typedef RemovedItemBuilder<T> =
    Widget Function(T item, BuildContext context, Animation<double> animation);

class AnimatedEventList extends StatefulWidget {
  const AnimatedEventList({super.key});

  @override
  State<AnimatedEventList> createState() => _AnimatedEventListState();
}

class _AnimatedEventListState extends State<AnimatedEventList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<SexualEvent> _list;
  List<SexualEvent>? _previousEvents;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SexualEventsProvider>();
    final currentEvents = provider.state.currentEvents ?? [];
    _list = ListModel<SexualEvent>(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: currentEvents,
    );
    _previousEvents = currentEvents;
  }

  void _syncIfChanged(List<SexualEvent> newEvents) {
    // Only sync if the events list actually changed
    if (_previousEvents == null ||
        _previousEvents!.length != newEvents.length ||
        !_eventsEqual(_previousEvents!, newEvents)) {
      _list.syncWith(newEvents);
      _previousEvents = newEvents;
    }
  }

  bool _eventsEqual(List<SexualEvent> a, List<SexualEvent> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Widget _buildItem(
    int index,
    BuildContext context,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: EventCard(event: _list[index]),
    );
  }

  Widget _buildRemovedItem(
    SexualEvent event,
    BuildContext context,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: EventCard(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SexualEventsProvider>();
    final currentEvents = provider.state.currentEvents ?? [];

    // Only sync if events actually changed
    _syncIfChanged(currentEvents);

    return Expanded(
      child: AnimatedList(
        key: _listKey,
        initialItemCount: _list.length,
        itemBuilder: (context, index, animation) =>
            _buildItem(index, context, animation),
      ),
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
