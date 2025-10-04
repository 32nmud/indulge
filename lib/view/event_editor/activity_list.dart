import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models/sexual_activity.dart';
import 'package:indulge/provider/event_provider.dart';
import 'activity_card.dart';

typedef RemovedItemBuilder<T> = Widget Function(
    T item, BuildContext context, Animation<double> animation);

class AnimatedEventActivityList extends StatefulWidget {
  const AnimatedEventActivityList({super.key});

  @override
  State<AnimatedEventActivityList> createState() =>
      _AnimatedEventActivityListState();
}

class _AnimatedEventActivityListState extends State<AnimatedEventActivityList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<SexualActivity> _list;

  @override
  void initState() {
    super.initState();
    final provider = context.read<EventsProvider>();
    _list = ListModel<SexualActivity>(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: provider.state.selectedEvent?.activities ?? [],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<EventsProvider>();
    _list.syncWith(provider.state.selectedEvent?.activities ?? []);
  }

  Widget _buildItem(
      int index, BuildContext context, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ActivityCard(activity: _list[index]),
    );
  }

  Widget _buildRemovedItem(SexualActivity activity, BuildContext context,
      Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ActivityCard(activity: activity),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<EventsProvider>();

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
