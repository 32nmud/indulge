import 'package:flutter/material.dart';

class AddItemCard extends StatefulWidget {
  const AddItemCard({super.key});

  @override
  State<AddItemCard> createState() => _AddItemCardState();
}

class _AddItemCardState extends State<AddItemCard> {
  Widget _addButton() {
    return IconButton(
      icon: Icon(Icons.add),
      onPressed: () => {},
    );
  }

  Widget _activityCard(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
                children: [_addButton()],
                mainAxisAlignment: MainAxisAlignment.center)));
  }

  @override
  Widget build(BuildContext context) {
    return _activityCard(context);
  }
}
