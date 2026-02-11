/// Base interface for versioned models that support migration
abstract class VersionedModel {
  /// The version number of this model
  /// Version 1 (or null) = original model
  /// Version 2 = renamed terminology (activities → categories, properties → activities)
  int get version;

  /// The resource type identifier
  String get resourceType;

  /// Converts this model to JSON with version information
  Map<String, dynamic> toJson();
}

/// Utility class for handling model version migrations
class ModelVersionMigration {
  /// The current/latest version of all models
  static const int currentVersion = 2;

  /// Determines the version of a model from its JSON data
  /// Returns 1 if no version field is present (legacy data)
  static int getVersion(Map<String, dynamic> json) {
    return json['version'] as int? ?? 1;
  }

  /// Checks if a document needs migration
  static bool needsMigration(Map<String, dynamic> json) {
    return getVersion(json) < currentVersion;
  }

  /// Adds version information to JSON before saving
  static Map<String, dynamic> addVersion(
    Map<String, dynamic> json,
    int version,
  ) {
    return {...json, 'version': version};
  }

  /// Creates a migration log entry
  static Map<String, dynamic> createMigrationMetadata(
    int fromVersion,
    int toVersion,
  ) {
    return {
      'migratedFrom': fromVersion,
      'migratedTo': toVersion,
      'migrationDate': DateTime.now().toIso8601String(),
    };
  }
}

/// Exception thrown when a migration fails
class ModelMigrationException implements Exception {
  final String message;
  final String resourceType;
  final int fromVersion;
  final int toVersion;
  final Object? cause;

  ModelMigrationException({
    required this.message,
    required this.resourceType,
    required this.fromVersion,
    required this.toVersion,
    this.cause,
  });

  @override
  String toString() {
    final causeStr = cause != null ? '\nCause: $cause' : '';
    return 'ModelMigrationException: Failed to migrate $resourceType '
        'from v$fromVersion to v$toVersion: $message$causeStr';
  }
}

/// Interface for model migrators
abstract class ModelMigrator<TFrom, TTo> {
  /// The version this migrator upgrades from
  int get fromVersion;

  /// The version this migrator upgrades to
  int get toVersion;

  /// The resource type this migrator handles
  String get resourceType;

  /// Performs the migration
  TTo migrate(TFrom oldModel);

  /// Validates that the migrated model is correct
  bool validate(TTo newModel) => true;

  /// Deserializes a v1 model from JSON
  /// This is used by SQLite migration service to convert JSON to model objects
  TFrom deserializeV1(Map<String, dynamic> json);

  /// Serializes a v2 model to JSON
  /// This is used by SQLite migration service to convert model objects back to JSON
  Map<String, dynamic> serializeV2(TTo model);
}
