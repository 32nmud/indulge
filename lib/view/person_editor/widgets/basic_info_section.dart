import 'package:flutter/material.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nicknameController;
  final TextEditingController givenNameController;
  final TextEditingController familyNameController;
  final DateTime? birthday;
  final VoidCallback onPickBirthday;
  final VoidCallback onClearBirthday;

  const BasicInfoSection({
    super.key,
    required this.nicknameController,
    required this.givenNameController,
    required this.familyNameController,
    required this.birthday,
    required this.onPickBirthday,
    required this.onClearBirthday,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'How you refer to them',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: givenNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: familyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (birthday == null)
              OutlinedButton.icon(
                icon: const Icon(Icons.cake),
                label: const Text('Add Birthday'),
                onPressed: onPickBirthday,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake),
                title: Text(_formatDate(birthday!)),
                subtitle: Text('Age: ${_calculateAge(birthday!)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClearBirthday,
                ),
                onTap: onPickBirthday,
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
