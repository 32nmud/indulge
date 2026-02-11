import 'package:flutter/material.dart';

class BodyInfoSection extends StatelessWidget {
  final TextEditingController bodyTypeController;
  final TextEditingController endowmentController;
  final TextEditingController breastSizeController;
  final TextEditingController heightController;
  final String? cutStatus;
  final ValueChanged<String?> onCutStatusChanged;
  final String? assignedSexAtBirth;
  final ValueChanged<String?> onAssignedSexAtBirthChanged;

  const BodyInfoSection({
    super.key,
    required this.bodyTypeController,
    required this.endowmentController,
    required this.breastSizeController,
    required this.heightController,
    this.cutStatus,
    required this.onCutStatusChanged,
    this.assignedSexAtBirth,
    required this.onAssignedSexAtBirthChanged,
  });

  static const List<String> _bodyTypes = [
    'Average',
    'Twink',
    'Twunk',
    'Otter',
    'Athletic',
    'Bodybuilder',
    'Jock',
    'Butch',
    'Chub',
    'Cub',
    'Bear',
    'Daddy',
    'Femme',
    'Pup',
  ];

  @override
  Widget build(BuildContext context) {
    final isAMAB = assignedSexAtBirth == 'AMAB';
    final isAFAB = assignedSexAtBirth == 'AFAB';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Body Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<String>(
                  width: constraints.maxWidth,
                  controller: bodyTypeController,
                  label: const Text('Body Type'),
                  menuHeight: 250,
                  enableFilter: true,
                  requestFocusOnTap: false,
                  leadingIcon: const Icon(Icons.accessibility_new),
                  dropdownMenuEntries: _bodyTypes
                      .map<DropdownMenuEntry<String>>((String type) {
                        return DropdownMenuEntry<String>(
                          value: type,
                          label: type,
                        );
                      })
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildSexSelector(context),
            if (isAMAB) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Uncut'),
                value: cutStatus == 'Uncut',
                onChanged: (bool? value) {
                  onCutStatusChanged(value == true ? 'Uncut' : 'Cut');
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endowmentController,
                decoration: const InputDecoration(
                  labelText: 'Endowment',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            if (isAFAB) ...[
              const SizedBox(height: 16),
              TextField(
                controller: breastSizeController,
                decoration: const InputDecoration(
                  labelText: 'Breast Size',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSexSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Sex at Birth',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Male'),
              selected: assignedSexAtBirth == 'AMAB',
              onSelected: (selected) {
                onAssignedSexAtBirthChanged(selected ? 'AMAB' : null);
              },
            ),
            ChoiceChip(
              label: const Text('Female'),
              selected: assignedSexAtBirth == 'AFAB',
              onSelected: (selected) {
                onAssignedSexAtBirthChanged(selected ? 'AFAB' : null);
              },
            ),
          ],
        ),
      ],
    );
  }
}
