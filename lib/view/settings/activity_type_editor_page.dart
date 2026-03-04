import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/reorder_buttons.dart';
import 'package:uuid/uuid.dart';

class ActivityTypeEditorPage extends StatefulWidget {
  final SexualActivityCategory? activityCategory;

  const ActivityTypeEditorPage({super.key, this.activityCategory});

  @override
  State<ActivityTypeEditorPage> createState() => _ActivityTypeEditorPageState();
}

class _ActivityTypeEditorPageState extends State<ActivityTypeEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late List<_ActivityRow> _activities;

  // Subcategories stored as full objects so display never depends on a map
  // lookup that might silently return null.
  late List<SexualActivityCategory> _selectedSubcats;

  // IDs of subcategories that were created inline during this editing session
  // and have NOT yet been persisted to the store.  They are saved as part of
  // _saveActivityCategory so they never appear as orphan top-level categories.
  final Set<String> _pendingNewSubcatIds = {};

  bool _isLoading = false;
  bool _requiresPartner = false;

  // All categories available to be picked as subcategories.
  // Excludes self. Also excludes categories that are already subcategories
  // (only one level of nesting allowed).
  List<SexualActivityCategory> _pickableCats = [];

  // Whether the category being edited is itself used as a subcategory of
  // another category. If so, the subcategory section is hidden entirely.
  bool _isSubcategoryItself = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.activityCategory?.name ?? '',
    );
    _emojiController = TextEditingController(
      text: widget.activityCategory?.displayCharacter ?? '❓',
    );
    _requiresPartner = widget.activityCategory?.requiresPartner ?? false;

    // ── Activities ─────────────────────────────────────────────────
    _activities = [];
    if (widget.activityCategory != null) {
      for (final act in widget.activityCategory!.activities) {
        _activities.add(
          _ActivityRow(
            nameController: TextEditingController(text: act.name),
            emojiController: TextEditingController(text: act.displayCharacter),
            stiRisk: act.stiRisk,
            healthRisk: act.healthRisk,
            requiresPartner: act.requiresPartner,
            canHaveMultipleParticipants: act.canHaveMultipleParticipants,
            isActionable: act.isActionable,
            sortOrder: act.sortOrder,
          ),
        );
      }
      _activities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    // ── Subcategories ──────────────────────────────────────────────
    final store = context.read<EventStateStore>();
    final allCats = Map<String, SexualActivityCategory>.from(
      store.state.sexualActivityCategories ?? {},
    );

    // Collect all IDs that are already used as a subcategory somewhere.
    final usedAsSubcatIds = <String>{};
    for (final cat in allCats.values) {
      for (final ref in cat.subCategories) {
        if (ref.reference.isNotEmpty) usedAsSubcatIds.add(ref.reference);
      }
    }

    // Is the category being edited itself a subcategory of something?
    _isSubcategoryItself =
        widget.activityCategory != null &&
        usedAsSubcatIds.contains(widget.activityCategory!.id);

    // Resolve currently selected subcats from the saved references.
    _selectedSubcats = [];
    if (widget.activityCategory != null) {
      for (final ref in widget.activityCategory!.subCategories) {
        if (ref.reference.isEmpty) continue;
        final cat = allCats[ref.reference];
        if (cat != null) _selectedSubcats.add(cat);
      }
    }

    // Pickable = exists in store, not self, not already a subcategory of
    // anything (so we only allow one nesting level), and not already selected.
    final selfId = widget.activityCategory?.id;
    _pickableCats =
        allCats.values
            .where(
              (c) =>
                  c.id != selfId &&
                  !usedAsSubcatIds.contains(c.id) &&
                  !_selectedSubcats.any((s) => s.id == c.id),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    for (final row in _activities) {
      row.nameController.dispose();
      row.emojiController.dispose();
    }
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activityCategory == null ? 'New Category' : 'Edit Category',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: _saveActivityCategory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryHeader(context),
                    const SizedBox(height: 8),
                    _buildCategoryOptions(context),
                    // Only top-level categories can have subcategories.
                    if (!_isSubcategoryItself) ...[
                      const SizedBox(height: 24),
                      _buildSubcategoriesSection(context),
                    ],
                    const SizedBox(height: 24),
                    _buildActivitiesSection(context),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveActivityCategory,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.activityCategory == null ? 'Create' : 'Save',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Section builders
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCategoryHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: _emojiController,
            decoration: const InputDecoration(
              labelText: 'Emoji',
              border: OutlineInputBorder(),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32),
            maxLength: 2,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name *',
              hintText: 'e.g., Oral, Vaginal, Manual…',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryOptions(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requires Partner',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Activities in this category involve another person',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _requiresPartner,
              onChanged: (v) => setState(() => _requiresPartner = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subcategories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Group related categories under this one',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () => _addSubcategory(context),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Empty state ──────────────────────────────────────────────
        if (_selectedSubcats.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No subcategories — tap Add to attach existing categories',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          // ── Subcategory rows ────────────────────────────────────────
          Column(
            children: [
              for (var i = 0; i < _selectedSubcats.length; i++)
                _buildSubcatRow(context, i),
            ],
          ),
      ],
    );
  }

  Widget _buildSubcatRow(BuildContext context, int index) {
    final cat = _selectedSubcats[index];
    final isFirst = index == 0;
    final isLast = index == _selectedSubcats.length - 1;

    return Card(
      key: ValueKey(cat.id),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            ReorderButtons(
              isFirst: isFirst,
              isLast: isLast,
              onUp: () => setState(() {
                final item = _selectedSubcats.removeAt(index);
                _selectedSubcats.insert(index - 1, item);
              }),
              onDown: () => setState(() {
                final item = _selectedSubcats.removeAt(index);
                _selectedSubcats.insert(index + 1, item);
              }),
            ),
            const SizedBox(width: 8),
            Text(
              cat.displayCharacter ?? '❔',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (cat.activities.isNotEmpty)
                    Text(
                      '${cat.activities.length} '
                      '${cat.activities.length == 1 ? 'activity' : 'activities'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              tooltip: 'Remove subcategory',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  // Put it back in the pickable list.
                  _pickableCats.add(cat);
                  _pickableCats.sort((a, b) => a.name.compareTo(b.name));
                  _selectedSubcats.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Specific actions within this category',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: _addActivity,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_activities.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No activities yet — tap Add to create one',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < _activities.length; i++)
                _buildActivityRow(context, i, _activities[i]),
            ],
          ),
      ],
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    int index,
    _ActivityRow activity,
  ) {
    final isFirst = index == 0;
    final isLast = index == _activities.length - 1;

    return Card(
      key: ValueKey(index),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderButtons(
                  isFirst: isFirst,
                  isLast: isLast,
                  onUp: () => _moveActivity(index, index - 1),
                  onDown: () => _moveActivity(index, index + 1),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 64,
                  child: TextFormField(
                    controller: activity.emojiController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                    maxLength: 2,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return '!';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: activity.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Name',
                      hintText: 'e.g., Giving, Receiving…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name required';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove activity',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeActivity(index),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: const Text(
                    'Actionable',
                    style: TextStyle(fontSize: 12),
                  ),
                  tooltip:
                      'Appears as a selectable activity in the event editor',
                  selected: activity.isActionable,
                  onSelected: (v) => setState(() => activity.isActionable = v),
                ),
                FilterChip(
                  label: Text(
                    'STI Risk',
                    style: TextStyle(
                      fontSize: 12,
                      color: activity.stiRisk ? Colors.white : null,
                    ),
                  ),
                  selected: activity.stiRisk,
                  selectedColor: Colors.purple.shade700,
                  onSelected: (v) => setState(() => activity.stiRisk = v),
                ),
                FilterChip(
                  label: Text(
                    'Health Risk',
                    style: TextStyle(
                      fontSize: 12,
                      color: activity.healthRisk ? Colors.white : null,
                    ),
                  ),
                  selected: activity.healthRisk,
                  selectedColor: Colors.orange.shade700,
                  onSelected: (v) => setState(() => activity.healthRisk = v),
                ),
                FilterChip(
                  label: const Text(
                    'Needs Partner',
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: activity.requiresPartner,
                  onSelected: (v) =>
                      setState(() => activity.requiresPartner = v),
                ),
                FilterChip(
                  label: const Text(
                    'Multi-participant',
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: activity.canHaveMultipleParticipants,
                  onSelected: (v) =>
                      setState(() => activity.canHaveMultipleParticipants = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Add subcategory (creates a new category and attaches it)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _addSubcategory(BuildContext context) async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '❔');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Subcategory'),
        content: Form(
          key: formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: TextFormField(
                  controller: emojiController,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22),
                  maxLength: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Giving, Receiving…',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Capture values before any disposal.
    final name = nameController.text.trim();
    final emoji = emojiController.text.trim();

    // Defer disposal until after this frame so the dialog's TextFormField
    // widgets have fully unmounted before the controllers are released.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      emojiController.dispose();
    });

    final newCat = SexualActivityCategory(
      id: const Uuid().v4(),
      name: name,
      displayCharacter: emoji,
    );

    // Don't persist the new subcategory yet.  It will be saved together with
    // the parent in _saveActivityCategory, preventing it from appearing as a
    // spurious top-level category in the meantime.
    setState(() {
      _pendingNewSubcatIds.add(newCat.id);
      _selectedSubcats.add(newCat);
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Mutations
  // ───────────────────────────────────────────────────────────────────────────

  void _moveActivity(int from, int to) {
    if (from == to) return;
    setState(() {
      final row = _activities.removeAt(from);
      _activities.insert(to, row);
      for (var i = 0; i < _activities.length; i++) {
        _activities[i].sortOrder = i;
      }
    });
  }

  void _addActivity() {
    setState(() {
      _activities.add(
        _ActivityRow(
          nameController: TextEditingController(),
          emojiController: TextEditingController(text: '❔'),
          stiRisk: false,
          healthRisk: false,
          requiresPartner: false,
          canHaveMultipleParticipants: true,
          isActionable: true,
          sortOrder: _activities.length,
        ),
      );
    });
  }

  Future<void> _removeActivity(int index) async {
    final activityRow = _activities[index];
    final activityName = activityRow.nameController.text.trim();
    final categoryId = widget.activityCategory?.id ?? '';

    final isExisting =
        widget.activityCategory?.activities.any(
          (a) => a.name == activityName,
        ) ??
        false;

    if (isExisting && categoryId.isNotEmpty) {
      final provider = context.read<SexualEventsProvider>();
      final count = await provider.getUsageCountForActivity(categoryId);

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Activity?'),
          content: Text(
            count > 0
                ? '"$activityName" is recorded in $count existing '
                      'event${count == 1 ? '' : 's'}. Removing it will '
                      'delete those records.'
                : 'Remove "$activityName" from this category?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await provider.deleteSexualActivity(
        categoryId: categoryId,
        activityName: activityName,
      );
    }

    if (!mounted) return;

    setState(() {
      _activities[index].nameController.dispose();
      _activities[index].emojiController.dispose();
      _activities.removeAt(index);
      for (var i = 0; i < _activities.length; i++) {
        _activities[i].sortOrder = i;
      }
    });
  }

  Future<void> _saveActivityCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<SexualEventsProvider>();

      final embeddedActivities = <SexualActivity>[];
      for (var i = 0; i < _activities.length; i++) {
        final row = _activities[i];
        embeddedActivities.add(
          SexualActivity(
            name: row.nameController.text.trim(),
            displayCharacter: row.emojiController.text.trim(),
            stiRisk: row.stiRisk,
            healthRisk: row.healthRisk,
            requiresPartner: row.requiresPartner,
            canHaveMultipleParticipants: row.canHaveMultipleParticipants,
            isActionable: row.isActionable,
            sortOrder: i,
          ),
        );
      }

      // Persist any subcategories that were created inline during this session
      // before we write the parent (which references them by ID).
      for (final sub in _selectedSubcats) {
        if (_pendingNewSubcatIds.contains(sub.id)) {
          await provider.saveActivityCategory(sub);
        }
      }
      _pendingNewSubcatIds.clear();

      final subCategoryRefs = _selectedSubcats
          .map(
            (cat) => Reference(
              reference: cat.id,
              resourceType: 'SexualActivityCategory',
            ),
          )
          .toList();

      final activityCategory = SexualActivityCategory(
        id: widget.activityCategory?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        displayCharacter: _emojiController.text.trim(),
        activities: embeddedActivities,
        requiresPartner: _requiresPartner,
        sortOrder: widget.activityCategory?.sortOrder ?? 0,
        subCategories: subCategoryRefs,
      );

      await provider.saveActivityCategory(activityCategory);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActivityRow  –  mutable state for one activity in the editor
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityRow {
  final TextEditingController nameController;
  final TextEditingController emojiController;
  bool stiRisk;
  bool healthRisk;
  bool requiresPartner;
  bool canHaveMultipleParticipants;
  bool isActionable;
  int sortOrder;

  _ActivityRow({
    required this.nameController,
    required this.emojiController,
    required this.stiRisk,
    required this.healthRisk,
    required this.requiresPartner,
    required this.canHaveMultipleParticipants,
    required this.isActionable,
    required this.sortOrder,
  });
}
