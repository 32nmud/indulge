import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models/v1/sexual_activity_type_property/sexual_activity_type_property.dart'
    as v1;
import 'package:indulge/data/models/v2/sexual_activity/sexual_activity.dart'
    as v2;
import 'package:indulge/data/models/v3/sexual_activity/sexual_activity.dart'
    as v3;
import 'package:indulge/domain/database/migration/migrators.dart';

void main() {
  group('SexualActivity migrations', () {
    test(
      'v2 -> v3 migrator converts isRisky into stiRisk and healthRisk (true)',
      () {
        final v2Activity = v2.SexualActivity(
          id: 'act-1',
          name: 'Bottoming (bareback)',
          displayCharacter: '🍑',
          canHaveMultipleParticipants: false,
          isRisky: true,
          requiresPartner: true,
        );

        final migrator = MigratorRegistry.getMigrator('SexualActivity', 2, 3);
        expect(
          migrator,
          isNotNull,
          reason: 'v2->v3 migrator should be registered',
        );

        final migrated = migrator!.migrate(v2Activity) as v3.SexualActivity;

        // Both STI and general health risk should reflect the old isRisky flag
        expect(migrated.stiRisk, isTrue);
        expect(migrated.healthRisk, isTrue);

        // Ensure identity of basic fields preserved
        expect(migrated.id, equals(v2Activity.id));
        expect(migrated.name, equals(v2Activity.name));
        expect(migrated.displayCharacter, equals(v2Activity.displayCharacter));
      },
    );

    test(
      'v2 -> v3 migrator converts isRisky into stiRisk and healthRisk (false)',
      () {
        final v2Activity = v2.SexualActivity(
          id: 'act-2',
          name: 'Kissing',
          displayCharacter: '💋',
          canHaveMultipleParticipants: false,
          isRisky: false,
          requiresPartner: true,
        );

        final migrator = MigratorRegistry.getMigrator('SexualActivity', 2, 3);
        expect(
          migrator,
          isNotNull,
          reason: 'v2->v3 migrator should be registered',
        );

        final migrated = migrator!.migrate(v2Activity) as v3.SexualActivity;

        expect(migrated.stiRisk, isFalse);
        expect(migrated.healthRisk, isFalse);

        expect(migrated.id, equals(v2Activity.id));
        expect(migrated.name, equals(v2Activity.name));
      },
    );

    test(
      'v1 -> v3 full migration (via v1->v2 then v2->v3) preserves risk info',
      () {
        // Create a v1 model (SexualActivityTypeProperty) with isRisky true
        final v1Activity = v1.SexualActivityTypeProperty(
          id: 'v1-act-1',
          name: 'Fisting',
          displayCharacter: '✋',
          canHaveMultipleParticipants: false,
          isRisky: true,
          requiresPartner: true,
        );

        // Step 1: v1 -> v2
        final migratorV1toV2 = MigratorRegistry.getMigrator(
          'SexualActivityTypeProperty',
          1,
          2,
        );
        expect(
          migratorV1toV2,
          isNotNull,
          reason: 'v1->v2 migrator for SexualActivityTypeProperty should exist',
        );

        final v2Model =
            migratorV1toV2!.migrate(v1Activity) as v2.SexualActivity;

        // The v2 model should reflect the original isRisky flag
        expect(v2Model.isRisky, equals(v1Activity.isRisky));

        // Step 2: v2 -> v3
        final migratorV2toV3 = MigratorRegistry.getMigrator(
          'SexualActivity',
          2,
          3,
        );
        expect(
          migratorV2toV3,
          isNotNull,
          reason: 'v2->v3 migrator for SexualActivity should exist',
        );

        final v3Model = migratorV2toV3!.migrate(v2Model) as v3.SexualActivity;

        // Verify both new flags are set based on the original v1.isRisky
        expect(v3Model.stiRisk, equals(v1Activity.isRisky));
        expect(v3Model.healthRisk, equals(v1Activity.isRisky));

        // Ensure name/id preserved across migrations
        expect(v3Model.name, equals(v1Activity.name));
        expect(v3Model.id, equals(v1Activity.id));
      },
    );

    test(
      'v1 -> v3 full migration (via v1->v2 then v2->v3) preserves risk info (false)',
      () {
        // Create a v1 model with isRisky false
        final v1Activity = v1.SexualActivityTypeProperty(
          id: 'v1-act-2',
          name: 'Cuddling',
          displayCharacter: '🤗',
          canHaveMultipleParticipants: false,
          isRisky: false,
          requiresPartner: true,
        );

        final migratorV1toV2 = MigratorRegistry.getMigrator(
          'SexualActivityTypeProperty',
          1,
          2,
        );
        expect(migratorV1toV2, isNotNull);

        final v2Model =
            migratorV1toV2!.migrate(v1Activity) as v2.SexualActivity;
        expect(v2Model.isRisky, equals(false));

        final migratorV2toV3 = MigratorRegistry.getMigrator(
          'SexualActivity',
          2,
          3,
        );
        expect(migratorV2toV3, isNotNull);

        final v3Model = migratorV2toV3!.migrate(v2Model) as v3.SexualActivity;
        expect(v3Model.stiRisk, isFalse);
        expect(v3Model.healthRisk, isFalse);
      },
    );
  });
}
