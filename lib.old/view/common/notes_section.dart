import 'package:flutter/material.dart';

class NotesSection extends StatefulWidget {
  final String? initialNotes;
  final ValueChanged<String> onNotesChanged;
  final String hintText;

  const NotesSection({
    super.key,
    this.initialNotes,
    required this.onNotesChanged,
    this.hintText = 'Add notes (Markdown supported)...',
  });

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: null,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: widget.onNotesChanged,
        ),
      ],
    );
  }
}
