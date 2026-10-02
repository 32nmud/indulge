import 'package:logging/logging.dart';

/// Central service for handling model version migrations
///
/// Currently a stub - migration logic was removed during legacy cleanup.
/// The framework is preserved for future migration implementation.
class MigrationService {
  static final Logger _logger = Logger('MigrationService');

  /// The current/latest version of all models
  static const int currentVersion = 1;

  /// Migrates a model to the latest version if needed
  ///
  /// STUB: Currently returns the input as-is without any migration.
  /// Will need to be reimplemented for actual data migration.
  static Future<T> migrateIfNeeded<T>(
    Map<String, dynamic> json,
    String resourceType,
  ) async {
    _logger.fine(
      'Migration stub: returning $resourceType as-is (version handling not implemented)',
    );
    // TODO: Reimplement migration logic
    throw UnimplementedError('Migration not yet implemented');
  }

  /// Checks if a JSON document needs migration
  static bool needsMigration(Map<String, dynamic> json) {
    return false; // Stub - always returns false
  }

  /// Gets the version of a JSON document
  static int getVersion(Map<String, dynamic> json) {
    return currentVersion;
  }

  /// Migrates a list of models
  static Future<List<T>> migrateListIfNeeded<T>(
    List<Map<String, dynamic>> jsonList,
    String resourceType,
  ) async {
    throw UnimplementedError('Migration not yet implemented');
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
