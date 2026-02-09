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

  @override
  void initState() {
    super.initState();
    final provider = context.read<SexualEventsProvider>();
    _list = ListModel<SexualEvent>(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: provider.state.currentEvents ?? [],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SexualEventsProvider>();
    _list.syncWith(provider.state.currentEvents ?? []);
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
    context.watch<SexualEventsProvider>();

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
