import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:uuid/uuid.dart';

class PersonEditorPage extends StatefulWidget {
  final Person? person;

  const PersonEditorPage({super.key, this.person});

  @override
  State<PersonEditorPage> createState() => _PersonEditorPageState();
}

class _PersonEditorPageState extends State<PersonEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _nicknameController;
  DateTime? _birthday;
  DateTime _dateAdded = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.person != null) {
      // Editing existing person
      _givenNameController = TextEditingController(
        text: widget.person!.name.given,
      );
      _familyNameController = TextEditingController(
        text: widget.person!.name.family,
      );
      _nicknameController = TextEditingController(
        text: widget.person!.name.nickname,
      );
      _birthday = widget.person!.birthday;
      _dateAdded = widget.person!.date;
    } else {
      // Creating new person
      _givenNameController = TextEditingController();
      _familyNameController = TextEditingController();
      _nicknameController = TextEditingController();
      _birthday = null;
      _dateAdded = DateTime.now();
    }
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthday ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Birthday',
    );

    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  void _clearBirthday() {
    setState(() {
      _birthday = null;
    });
  }

  bool _validateForm() {
    // At least one name field must be filled
    if (_givenNameController.text.trim().isEmpty &&
        _familyNameController.text.trim().isEmpty &&
        _nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one name field'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _savePerson() async {
    if (!_validateForm()) return;

    try {
      final name = Name(
        given: _givenNameController.text.trim().isNotEmpty
            ? _givenNameController.text.trim()
            : null,
        family: _familyNameController.text.trim().isNotEmpty
            ? _familyNameController.text.trim()
            : null,
        nickname: _nicknameController.text.trim().isNotEmpty
            ? _nicknameController.text.trim()
            : null,
      );

      // Generate UUID explicitly for new persons
      final personId = widget.person?.id ?? const Uuid().v4();

      final person = Person(
        id: personId,
        date: _dateAdded,
        lastUpdateDate: DateTime.now(),
        name: name,
        birthday: _birthday,
      );

      final provider = context.read<SexualEventsProvider>();
      await provider.savePerson(person);

      if (mounted) {
        Navigator.pop(context, person);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? 'New Contact' : 'Edit Contact'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _savePerson),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameSection(),
              const SizedBox(height: 24),
              _buildBirthdaySection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Contact'),
                  onPressed: _savePerson,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'How you refer to them',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _givenNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                hintText: 'Given name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _familyNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                hintText: 'Family name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.family_restroom),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdaySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birthday (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_birthday == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cake),
                  label: const Text('Add Birthday'),
                  onPressed: _pickBirthday,
                ),
              )
            else
              ListTile(
                leading: const Icon(Icons.cake),
                title: Text(_formatDate(_birthday!)),
                subtitle: Text('Age: ${_calculateAge(_birthday!)} years'),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearBirthday,
                  tooltip: 'Remove birthday',
                ),
                onTap: _pickBirthday,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }
}
