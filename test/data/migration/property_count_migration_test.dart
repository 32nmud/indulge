import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models/v1/property_count/property_count.dart'
    as v1;
import 'package:indulge/data/models/v1/reference/reference.dart' as v1;
import 'package:indulge/data/models/v2/reference/reference.dart';
import 'package:indulge/data/models/v2/activity_count/activity_count.dart';
import 'package:indulge/data/models/versioned_model.dart';
import 'package:indulge/domain/database/migration/migration_service.dart';
import 'package:indulge/domain/database/migration/migrators.dart';

void main() {
  group('PropertyCount to ActivityCount Migration', () {
    test('migrator converts PropertyCount to ActivityCount correctly', () {
      final migrator = PropertyCountToActivityCountMigrator();

      final v1Model = v1.PropertyCount(
        propertyReference: v1.Reference(reference: 'prop_123'),
        count: 5,
      );

      final v2Model = migrator.migrate(v1Model);

      expect(v2Model.activityReference.reference, 'prop_123');
      expect(v2Model.count, 5);
      expect(v2Model.version, 2);
    });

    test('migrator validates migrated model', () {
      final migrator = PropertyCountToActivityCountMigrator();

      final validModel = ActivityCount(
        activityReference: Reference(reference: 'activity_123'),
        count: 3,
        version: 2,
      );

      expect(migrator.validate(validModel), true);
    });

    test('migrator rejects invalid count', () {
      final migrator = PropertyCountToActivityCountMigrator();

      final invalidModel = ActivityCount(
        activityReference: Reference(reference: 'activity_123'),
        count: -1,
        version: 2,
      );

      expect(migrator.validate(invalidModel), false);
    });

    test('migrator rejects invalid version', () {
      final migrator = PropertyCountToActivityCountMigrator();

      final invalidModel = ActivityCount(
        activityReference: Reference(reference: 'activity_123'),
        count: 3,
        version: 1,
      );

      expect(migrator.validate(invalidModel), false);
    });

    test('migrator rejects empty activity reference', () {
      final migrator = PropertyCountToActivityCountMigrator();

      final invalidModel = ActivityCount(
        activityReference: Reference(reference: ''),
        count: 3,
        version: 2,
      );

      expect(migrator.validate(invalidModel), false);
    });

    test('MigrationService detects v1 document without version field', () {
      final json = {
        'propertyReference': {'reference': 'prop_123'},
        'count': 5,
      };

      final version = MigrationService.getVersion(json);
      expect(version, 1); // Should default to v1
    });

    test('MigrationService detects v2 document with version field', () {
      final json = {
        'activityReference': {'reference': 'activity_123'},
        'count': 3,
        'version': 2,
      };

      final version = MigrationService.getVersion(json);
      expect(version, 2);
    });

    test('MigrationService detects migration needed for v1', () {
      final json = {
        'propertyReference': {'reference': 'prop_123'},
        'count': 5,
      };

      expect(MigrationService.needsMigration(json), true);
    });

    test('MigrationService detects no migration needed for v3', () {
      final json = {
        'activityReference': {'reference': 'activity_123'},
        'count': 3,
        'version': 3,
      };

      expect(MigrationService.needsMigration(json), false);
    });

    test(
      'MigrationService migrates v1 PropertyCount to v2 ActivityCount',
      () async {
        final v1Json = {
          'propertyReference': {'reference': 'prop_123'},
          'count': 5,
        };

        final result = await MigrationService.migrateIfNeeded<ActivityCount>(
          v1Json,
          'PropertyCount',
        );

        expect(result.activityReference.reference, 'prop_123');
        expect(result.count, 5);
        expect(result.version, 3);
      },
    );

    test(
      'MigrationService accepts ActivityCount as resource type for v1',
      () async {
        final v1Json = {
          'propertyReference': {'reference': 'prop_123'},
          'count': 3,
        };

        final result = await MigrationService.migrateIfNeeded<ActivityCount>(
          v1Json,
          'ActivityCount', // Using new name for old data
        );

        expect(result.activityReference.reference, 'prop_123');
        expect(result.count, 3);
        expect(result.version, 3);
      },
    );

    test(
      'MigrationService deserializes v2 directly without migration',
      () async {
        final v2Json = {
          'activityReference': {'reference': 'activity_123'},
          'count': 7,
          'version': 3,
        };

        final result = await MigrationService.migrateIfNeeded<ActivityCount>(
          v2Json,
          'ActivityCount',
        );

        expect(result.activityReference.reference, 'activity_123');
        expect(result.count, 7);
        expect(result.version, 3);
      },
    );

    test('MigrationService migrates list of models', () async {
      final jsonList = [
        {
          'propertyReference': {'reference': 'prop_1'},
          'count': 1,
        },
        {
          'propertyReference': {'reference': 'prop_2'},
          'count': 2,
        },
        {
          'activityReference': {'reference': 'activity_3'},
          'count': 3,
          'version': 3,
        },
      ];

      final results = await MigrationService.migrateListIfNeeded<ActivityCount>(
        jsonList,
        'ActivityCount',
      );

      expect(results.length, 3);
      expect(results[0].activityReference.reference, 'prop_1');
      expect(results[0].count, 1);
      expect(results[0].version, 3);

      expect(results[1].activityReference.reference, 'prop_2');
      expect(results[1].count, 2);
      expect(results[1].version, 3);

      expect(results[2].activityReference.reference, 'activity_3');
      expect(results[2].count, 3);
      expect(results[2].version, 3);
    });

    test('ModelVersionMigration.getVersion returns 1 for missing version', () {
      final json = {'someField': 'someValue'};
      expect(ModelVersionMigration.getVersion(json), 1);
    });

    test('ModelVersionMigration.getVersion returns explicit version', () {
      final json = {'version': 2, 'someField': 'someValue'};
      expect(ModelVersionMigration.getVersion(json), 2);
    });

    test('ModelVersionMigration.needsMigration returns true for v1', () {
      final json = {'someField': 'someValue'};
      expect(ModelVersionMigration.needsMigration(json), true);
    });

    test('ModelVersionMigration.needsMigration returns false for v3', () {
      final json = {'version': 3, 'someField': 'someValue'};
      expect(ModelVersionMigration.needsMigration(json), false);
    });

    test('ModelVersionMigration.addVersion adds version to JSON', () {
      final json = {'someField': 'someValue'};
      final withVersion = ModelVersionMigration.addVersion(json, 2);

      expect(withVersion['version'], 2);
      expect(withVersion['someField'], 'someValue');
      expect(withVersion.length, 2);
    });

    test('ModelVersionMigration.createMigrationMetadata creates metadata', () {
      final metadata = ModelVersionMigration.createMigrationMetadata(1, 2);

      expect(metadata['migratedFrom'], 1);
      expect(metadata['migratedTo'], 2);
      expect(metadata['migrationDate'], isNotNull);
      expect(metadata['migrationDate'], isA<String>());
    });

    test('MigratorRegistry finds PropertyCount to ActivityCount migrator', () {
      final migrator = MigratorRegistry.getMigrator('PropertyCount', 1, 2);

      expect(migrator, isNotNull);
      expect(migrator, isA<PropertyCountToActivityCountMigrator>());
      expect(migrator!.fromVersion, 1);
      expect(migrator.toVersion, 2);
    });

    test('MigratorRegistry returns null for unknown resource type', () {
      final migrator = MigratorRegistry.getMigrator('UnknownType', 1, 2);
      expect(migrator, isNull);
    });

    test(
      'MigratorRegistry.canMigrate returns true for available migration',
      () {
        expect(MigratorRegistry.canMigrate('PropertyCount', 1, 2), true);
      },
    );

    test(
      'MigratorRegistry.canMigrate returns false for unavailable migration',
      () {
        expect(MigratorRegistry.canMigrate('UnknownType', 1, 2), false);
      },
    );

    test('ActivityCount toJson includes version', () {
      final activityCount = ActivityCount(
        activityReference: Reference(reference: 'activity_123'),
        count: 5,
        version: 2,
      );

      final json = activityCount.toJson();

      expect(json['version'], 2);
      expect(json['count'], 5);
      // Reference should be serialized
      expect(json.containsKey('activityReference'), true);
    });

    test('ActivityCount fromJson deserializes correctly', () {
      final json = {
        'activityReference': {'reference': 'activity_123'},
        'count': 5,
        'version': 2,
      };

      final activityCount = ActivityCount.fromJson(json);

      expect(activityCount.version, 2);
      expect(activityCount.activityReference.reference, 'activity_123');
      expect(activityCount.count, 5);
    });

    test('ActivityCount implements VersionedModel', () {
      final activityCount = ActivityCount(
        activityReference: Reference(reference: 'activity_123'),
        count: 5,
        version: 2,
      );

      expect(activityCount, isA<VersionedModel>());
      expect(activityCount.version, 2);
      expect(activityCount.resourceType, 'ActivityCount');
    });

    test('Migration throws exception for future version', () async {
      final futureVersionJson = {
        'activityReference': {'reference': 'activity_123'},
        'count': 5,
        'version': 999,
      };

      expect(
        () => MigrationService.migrateIfNeeded<ActivityCount>(
          futureVersionJson,
          'ActivityCount',
        ),
        throwsA(isA<ModelMigrationException>()),
      );
    });

    test('Migration throws exception for unknown resource type', () async {
      final json = {'someField': 'someValue'};

      expect(
        () => MigrationService.migrateIfNeeded<ActivityCount>(
          json,
          'UnknownResourceType',
        ),
        throwsA(isA<ModelMigrationException>()),
      );
    });
  });
}
