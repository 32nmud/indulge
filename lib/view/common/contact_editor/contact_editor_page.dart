import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import '../notes_section.dart';
import 'widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ContactEditorPage extends StatefulWidget {
  final Person? person;

  const ContactEditorPage({super.key, this.person});

  @override
  State<ContactEditorPage> createState() => _ContactEditorPageState();
}

class _ContactEditorPageState extends State<ContactEditorPage> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _nicknameController;
  DateTime? _birthday;
  DateTime _dateAdded = DateTime.now();

  // Body Info
  late TextEditingController _bodyTypeController;
  late TextEditingController _endowmentController;
  late TextEditingController _breastSizeController;
  late TextEditingController _heightController;
  String? _cutStatus;
  String? _assignedSexAtBirth;

  // Personal Info
  late TextEditingController _genderController;
  late TextEditingController _pronounsController;
  late TextEditingController _hivStatusController;
  late TextEditingController _herpesStatusController;

  // Other
  late List<String> _socialLinks;
  String? _notes;
  String? _imageBytes;

  @override
  void initState() {
    super.initState();
    final p = widget.person;

    _dateAdded = p?.date ?? DateTime.now();
    _birthday = p?.birthday;

    // Basic
    _givenNameController = TextEditingController(text: p?.name.given);
    _familyNameController = TextEditingController(text: p?.name.family);
    _nicknameController = TextEditingController(text: p?.name.nickname);

    // Body
    _bodyTypeController = TextEditingController(text: p?.bodyType);
    _endowmentController = TextEditingController(text: p?.endowment);
    _breastSizeController = TextEditingController(text: p?.breastSize);
    _heightController = TextEditingController(text: p?.height);
    _cutStatus = p?.cutStatus;
    _assignedSexAtBirth = p?.assignedSexAtBirth;

    // Personal
    _genderController = TextEditingController(text: p?.gender);
    _pronounsController = TextEditingController(text: p?.pronouns);
    _hivStatusController = TextEditingController(text: p?.hivStatus);
    _herpesStatusController = TextEditingController(text: p?.herpesStatus);

    // Other
    _socialLinks = p?.socialLinks ?? [];
    _notes = p?.notes;
    _imageBytes = p?.imageBytes;
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _nicknameController.dispose();
    _bodyTypeController.dispose();
    _endowmentController.dispose();
    _breastSizeController.dispose();
    _heightController.dispose();
    _genderController.dispose();
    _pronounsController.dispose();
    _hivStatusController.dispose();
    _herpesStatusController.dispose();
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

      final personId = widget.person?.id ?? const Uuid().v4();

      final person = Person(
        id: personId,
        date: _dateAdded,
        lastUpdateDate: DateTime.now(),
        name: name,
        birthday: _birthday,
        isSelf: widget.person?.isSelf ?? false,
        // Body
        bodyType: _bodyTypeController.text.trim().isNotEmpty
            ? _bodyTypeController.text.trim()
            : null,
        endowment: _endowmentController.text.trim().isNotEmpty
            ? _endowmentController.text.trim()
            : null,
        breastSize: _breastSizeController.text.trim().isNotEmpty
            ? _breastSizeController.text.trim()
            : null,
        height: _heightController.text.trim().isNotEmpty
            ? _heightController.text.trim()
            : null,
        cutStatus: _cutStatus,
        assignedSexAtBirth: _assignedSexAtBirth,
        // Personal
        gender: _genderController.text.trim().isNotEmpty
            ? _genderController.text.trim()
            : null,
        pronouns: _pronounsController.text.trim().isNotEmpty
            ? _pronounsController.text.trim()
            : null,
        hivStatus: _hivStatusController.text.trim().isNotEmpty
            ? _hivStatusController.text.trim()
            : null,
        herpesStatus: _herpesStatusController.text.trim().isNotEmpty
            ? _herpesStatusController.text.trim()
            : null,
        // Other
        socialLinks: _socialLinks,
        notes: _notes,
        imageBytes: _imageBytes,
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePerson,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              PersonImagePicker(
                initialImageBytes: _imageBytes,
                onImageChanged: (val) => setState(() => _imageBytes = val),
              ),
              const SizedBox(height: 24),
              BasicInfoSection(
                nicknameController: _nicknameController,
                givenNameController: _givenNameController,
                familyNameController: _familyNameController,
                birthday: _birthday,
                onPickBirthday: _pickBirthday,
                onClearBirthday: _clearBirthday,
              ),
              const SizedBox(height: 16),
              BodyInfoSection(
                bodyTypeController: _bodyTypeController,
                endowmentController: _endowmentController,
                breastSizeController: _breastSizeController,
                heightController: _heightController,
                cutStatus: _cutStatus,
                onCutStatusChanged: (val) => setState(() => _cutStatus = val),
                assignedSexAtBirth: _assignedSexAtBirth,
                onAssignedSexAtBirthChanged: (val) =>
                    setState(() => _assignedSexAtBirth = val),
              ),
              const SizedBox(height: 16),
              PersonalInfoSection(
                genderController: _genderController,
                pronounsController: _pronounsController,
                hivStatusController: _hivStatusController,
                herpesStatusController: _herpesStatusController,
              ),
              const SizedBox(height: 16),
              SocialLinksSection(
                initialLinks: _socialLinks,
                onLinksChanged: (val) => setState(() => _socialLinks = val),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NotesSection(
                    initialNotes: _notes,
                    onNotesChanged: (val) => setState(() => _notes = val),
                  ),
                ),
              ),
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
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
