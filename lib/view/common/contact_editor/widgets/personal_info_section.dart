import 'package:flutter/material.dart';

class PersonalInfoSection extends StatefulWidget {
  final TextEditingController genderController;
  final TextEditingController pronounsController;
  final TextEditingController hivStatusController;
  final TextEditingController herpesStatusController;

  const PersonalInfoSection({
    super.key,
    required this.genderController,
    required this.pronounsController,
    required this.hivStatusController,
    required this.herpesStatusController,
  });

  @override
  State<PersonalInfoSection> createState() => _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends State<PersonalInfoSection> {
  late bool _isHivPositive;
  late bool _isHerpesPositive;

  @override
  void initState() {
    super.initState();
    _isHivPositive = widget.hivStatusController.text.isNotEmpty;
    _isHerpesPositive = widget.herpesStatusController.text.isNotEmpty;
  }

  void _updateHivStatus(bool? value) {
    setState(() {
      _isHivPositive = value ?? false;
      widget.hivStatusController.text = _isHivPositive ? 'Positive' : '';
    });
  }

  void _updateHerpesStatus(bool? value) {
    setState(() {
      _isHerpesPositive = value ?? false;
      widget.herpesStatusController.text = _isHerpesPositive ? 'Positive' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.genderController,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: widget.pronounsController,
                    decoration: const InputDecoration(
                      labelText: 'Pronouns',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('HIV+'),
              value: _isHivPositive,
              onChanged: _updateHivStatus,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Herpes+'),
              value: _isHerpesPositive,
              onChanged: _updateHerpesStatus,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
