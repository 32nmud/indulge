Phase 1: Disable Pages & Core Data Infrastructure (Foundation)

**1.1 - Disable All Pages**
- In `main.dart`, change the `IndexedStack` children to only show a placeholder/wip page initially
- Comment out or rename the actual page files:
  - `lib/view/home/` → rename to `*.dart.bk`
  - `lib/view/contacts/` → rename to `*.dart.bk`
  - `lib/view/search/` → rename to `*.dart.bk`
  - `lib/view/analysis/` → rename to `*.dart.bk`
  - `lib/view/settings/` → rename to `*.dart.bk`
- Create a temporary `WorkInProgressPage` to display while working on the data layer

**1.2 - Database Schema Updates**
- Update `assets/sql/schema.sql`:
  - Rename tables to be more consistent (e.g., `sexual_activity_type` → `activity_category`)
  - Add new `activity_subcategory` table
  - Add `is_tool/resource_item` flag to activity category or create separate table
  - Add `sort_order` columns for custom ordering
- Update `lib/domain/database/database_engine.dart` to reflect new table names

**1.3 - Model Version Cleanup**
- Delete `lib/data/models/v1/` entirely
- Delete `lib/data/models/v2/` entirely
- Rename `lib/data/models/v3/` → `lib/data/models/v1/` (new canonical version)
- Update `lib/data/models.dart` to export the new v1
- Update `lib/data/models/versioned_model.dart`:
  - Change `currentVersion` from 3 to 1
  - Clean up v1→v2, v2→v3 migration references

**1.4 - Migration Framework Cleanup**
- In `lib/domain/database/migration/`:
  - Delete or comment out v1→v2 and v2→v3 migrators in `migrators.dart`
  - Keep the `ModelMigrator` base class and `MigratorRegistry` framework for future use
  - Update `migration_service.dart` to remove v1/v2 deserialization logic
  - Simplify to assume incoming data is already "current version"

**1.5 - Update SexualActivityCategory Model (New V1)**
- Add `subcategories` field (List<Subcategory> or List<String> of subcategory IDs)
- Add `isTool` / `isResource` / `isItem` boolean flag
- Add `sortOrder` integer field
- Create new `SexualActivitySubcategory` model with:
  - `id`
  - `name`
  - `sortOrder`
  - `activityIds` (List<Reference>)

---

### Phase 2: Re-enable Home and Contacts Pages

**2.1 - Re-enable Home Page**
- Restore `lib/view/home/` files
- Update home page to handle subcategories:
  - Update category display to show subcategory tree
  - Update activity selection to filter by subcategory

**2.2 - Re-enable Contacts Page**
- Restore `lib/view/contacts/` files
- No major changes needed for contacts themselves, but may need to handle if contacts reference activities that are now tools/resources

---

### Phase 3: Settings Page Updates

**3.1 - Re-enable Settings Page**
- Restore `lib/view/settings/` files

**3.2 - Activity Type Editor Updates**
- Update `activity_type_editor_page.dart`:
  - Add UI for creating/editing subcategories
  - Add UI for marking activities as tools/resources/items
  - Add UI for custom sort order (drag-and-drop or manual order input)

**3.3 - Activity Type List Updates**
- Update `activity_type_list_page.dart`:
  - Display categories with subcategories nested
  - Add visual indicators for tool/resource items

---

### Phase 4: Search Page Updates

**4.1 - Re-enable Search Page**
- Restore `lib/view/search/` files

**4.2 - Filter Updates**
- Update search filters to support subcategories:
  - Allow filtering by subcategory
  - Allow filtering by tool/resource/activity type
  - Update filter UI to show category→subcategory hierarchy

---

### Phase 5: Analytics Page Updates

**5.1 - Re-enable Analysis Page**
- Restore `lib/view/analysis/` files

**5.2 - Analytics Updates**
- Update analytics to track tools/resources separately from activities
- Add new analytics views:
  - Tool usage analytics
  - Resource/item usage analytics
- Update existing analytics to filter out tools/resources where appropriate
