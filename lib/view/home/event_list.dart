import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/view/common/sexual_event_card.dart';

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
    final store = context.read<EventStateStore>();
    final currentEvents = store.state.currentEvents ?? [];
    _list = ListModel<SexualEvent>(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: currentEvents,
    );
    _previousEvents = currentEvents;
  }

  void _syncIfChanged(List<SexualEvent> newEvents) {
    // Only sync if the events list actually changed
    if (_previousEvents == null) {
      _list.syncWith(newEvents);
      _previousEvents = newEvents;
      return;
    }

    // Check if structure (IDs) changed
    final structureChanged =
        _previousEvents!.length != newEvents.length ||
        !_eventIdsEqual(_previousEvents!, newEvents);

    if (structureChanged) {
      // Structure changed: animate remove/insert
      _list.syncWith(newEvents);
      _previousEvents = newEvents;
    } else {
      // Check if content changed
      final contentChanged = !_eventsDeepEqual(_previousEvents!, newEvents);
      if (contentChanged) {
        // Content changed but IDs are same: update in place (no animation)
        _list.updateItems(newEvents);
        _previousEvents = newEvents;
      }
    }
  }

  bool _eventIdsEqual(List<SexualEvent> a, List<SexualEvent> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  bool _eventsDeepEqual(List<SexualEvent> a, List<SexualEvent> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildItem(
    int index,
    BuildContext context,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: SexualEventCard(event: _list[index]),
        ),
      ),
    );
  }

  Widget _buildRemovedItem(
    SexualEvent event,
    BuildContext context,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.1, 0),
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: SexualEventCard(event: event),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventStateStore>();
    final currentEvents = store.state.currentEvents ?? [];

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

  /// Updates the items list in place without triggering animations.
  /// Use this when the list items have changed but the list structure (IDs/order) is the same.
  void updateItems(Iterable<E> newItems) {
    _items.clear();
    _items.addAll(newItems);
  }

  /// Replaces the current items with [newItems], animating removals and insertions.
  void syncWith(Iterable<E> newItems) {
    final List<E> newList = List<E>.from(newItems);

    // Remove all old items first (from end to start to maintain indices)
    for (int i = _items.length - 1; i >= 0; i--) {
      final removed = _items[i];
      _animatedList?.removeItem(
        i,
        (context, animation) => removedItemBuilder(removed, context, animation),
        duration: const Duration(milliseconds: 150),
      );
    }
    _items.clear();

    // Insert all new items with a slight stagger
    for (int i = 0; i < newList.length; i++) {
      _items.add(newList[i]);
      final delayMs = i * 25; // Minimal stagger for smooth cascade
      Future.delayed(Duration(milliseconds: delayMs + 100), () {
        // Add delay before starting insertions to let removals complete
        _animatedList?.insertItem(
          i,
          duration: const Duration(milliseconds: 250),
        );
      });
    }
  }
}
