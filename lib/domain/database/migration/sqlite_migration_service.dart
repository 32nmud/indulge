import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/models/versioned_model.dart';
import 'v1_to_v2_migrators.dart';

/// Progress callback typedef
typedef ProgressCallback =
    void Function(String tableName, int current, int total, String status);

/// Service for handling SQLite database migrations
///
/// This service:
/// - Checks the database schema version
/// - Creates backups before migration
/// - Migrates tables from v1 to v2 format
/// - Tracks migration progress
/// - Handles errors and rollback
class SQLiteMigrationService {
  static final Logger _logger = Logger('SQLiteMigrationService');

  final Database database;
  final String databasePath;
  IOSink? _logFile;

  SQLiteMigrationService({required this.database, required this.databasePath});

  /// Initialize log file for migration
  Future<void> _initLogFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final logPath = '${logDir.path}/migration_$timestamp.log';

      final file = File(logPath);
      _logFile = file.openWrite(mode: FileMode.write);

      await _writeLog('Migration log started at ${DateTime.now()}');
      await _writeLog('Database path: $databasePath');

      _logger.info('Migration log file created at: $logPath');
    } catch (e) {
      _logger.warning('Failed to create log file: $e');
      // Non-fatal, continue without file logging
    }
  }

  /// Write a line to the log file
  Future<void> _writeLog(String message) async {
    if (_logFile != null) {
      _logFile!.writeln('[${DateTime.now().toIso8601String()}] $message');
      await _logFile!.flush();
    }
  }

  /// Close the log file
  Future<void> _closeLogFile() async {
    if (_logFile != null) {
      await _logFile!.close();
      _logFile = null;
    }
  }

  /// Check if migration is needed
  Future<bool> needsMigration() async {
    try {
      await ensureMetadataTableExists();

      final result = await database.query(
        'database_metadata',
        where: 'key = ?',
        whereArgs: ['schema_version'],
      );

      if (result.isEmpty) {
        _logger.info('No schema_version found, migration needed');
        return true;
      }

      final currentVersion = int.parse(result.first['value'] as String);
      _logger.info('Current schema version: $currentVersion');

      return currentVersion < ModelVersionMigration.currentVersion;
    } catch (e) {
      _logger.warning('Error checking migration status: $e');
      // If we can't determine, assume migration is needed
      return true;
    }
  }

  /// Get current schema version
  Future<int> getCurrentSchemaVersion() async {
    try {
      await ensureMetadataTableExists();

      final result = await database.query(
        'database_metadata',
        where: 'key = ?',
        whereArgs: ['schema_version'],
      );

      if (result.isEmpty) {
        return 1; // Default to v1 if not set
      }

      return int.parse(result.first['value'] as String);
    } catch (e) {
      _logger.warning('Error getting schema version: $e');
      return 1; // Default to v1 on error
    }
  }

  /// Ensure the database_metadata table exists
  Future<void> ensureMetadataTableExists() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS database_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Set a metadata value
  Future<void> setMetadata(String key, String value) async {
    await database.insert('database_metadata', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get a metadata value
  Future<String?> getMetadata(String key) async {
    final result = await database.query(
      'database_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  /// Create a backup of the database file
  Future<String> createBackup() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '$databasePath.backup-$timestamp';

      _logger.info('Creating backup at: $backupPath');

      // Close database connection temporarily for backup
      // Note: In production, you might want to use SQLite's backup API
      final dbFile = File(databasePath);
      await dbFile.copy(backupPath);

      _logger.info('Backup created successfully');
      return backupPath;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create backup', e, stackTrace);
      throw MigrationException(
        'Failed to create database backup: $e',
        isFatal: true,
      );
    }
  }

  /// Restore from a backup
  Future<void> restoreBackup(String backupPath) async {
    try {
      _logger.info('Restoring from backup: $backupPath');

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw MigrationException(
          'Backup file not found: $backupPath',
          isFatal: true,
        );
      }

      // Close database
      await database.close();

      // Restore backup
      await backupFile.copy(databasePath);

      _logger.info('Backup restored successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to restore backup', e, stackTrace);
      throw MigrationException(
        'Failed to restore database backup: $e',
        isFatal: true,
      );
    }
  }

  /// Check if migration is in progress (for crash recovery)
  Future<bool> isMigrationInProgress() async {
    final status = await getMetadata('migration_in_progress');
    return status == 'true';
  }

  /// Perform the full migration from v1 to v2
  Future<MigrationResult> migrate({ProgressCallback? onProgress}) async {
    final startTime = DateTime.now();
    String? backupPath;
    final migrationStats = <String, TableMigrationStats>{};

    // Initialize log file
    await _initLogFile();

    try {
      await _writeLog('Starting migration');

      // Check if already in progress
      if (await isMigrationInProgress()) {
        _logger.warning('Migration already in progress, clearing flag');
        await _writeLog(
          'WARNING: Migration already in progress, clearing flag',
        );
        await setMetadata('migration_in_progress', 'false');
      }

      // Mark migration as in progress
      await setMetadata('migration_in_progress', 'true');
      await _writeLog('Migration flag set');

      // Create backup
      onProgress?.call('backup', 0, 1, 'Creating backup...');
      backupPath = await createBackup();
      await _writeLog('Backup created at: $backupPath');

      // Migrate each table
      final tables = [
        'person',
        'sexual_activity_type',
        'sexual_activity_type_property',
        'sexual_event',
      ];

      for (var i = 0; i < tables.length; i++) {
        final table = tables[i];
        _logger.info('Migrating table: $table');
        await _writeLog('Starting migration of table: $table');

        onProgress?.call(table, i, tables.length, 'Migrating $table...');

        final stats = await _migrateTable(table);
        migrationStats[table] = stats;

        await _writeLog(
          'Completed table $table: ${stats.migratedCount} migrated, '
          '${stats.skippedCount} skipped, ${stats.errorCount} errors',
        );

        onProgress?.call(
          table,
          i + 1,
          tables.length,
          'Completed $table (${stats.migratedCount}/${stats.totalCount})',
        );
      }

      // Update schema version
      await setMetadata('schema_version', '2');
      await setMetadata(
        'migration_completed_at',
        DateTime.now().toIso8601String(),
      );
      await setMetadata('migration_in_progress', 'false');

      final duration = DateTime.now().difference(startTime);
      _logger.info(
        'Migration completed successfully in ${duration.inSeconds}s',
      );

      await _writeLog(
        'Migration completed successfully in ${duration.inSeconds}s',
      );
      await _writeLog('Total migrated: ${_getTotalMigrated(migrationStats)}');
      await _writeLog('Total skipped: ${_getTotalSkipped(migrationStats)}');
      await _writeLog('Total errors: ${_getTotalErrors(migrationStats)}');

      await _closeLogFile();

      return MigrationResult(
        success: true,
        backupPath: backupPath,
        duration: duration,
        tableStats: migrationStats,
      );
    } catch (e, stackTrace) {
      _logger.severe('Migration failed', e, stackTrace);
      await _writeLog('ERROR: Migration failed - $e');
      await _writeLog('Stack trace: $stackTrace');

      // Clear migration flag
      await setMetadata('migration_in_progress', 'false');

      await _closeLogFile();

      return MigrationResult(
        success: false,
        error: e.toString(),
        backupPath: backupPath,
        duration: DateTime.now().difference(startTime),
        tableStats: migrationStats,
      );
    }
  }

  int _getTotalMigrated(Map<String, TableMigrationStats> stats) =>
      stats.values.fold(0, (sum, s) => sum + s.migratedCount);

  int _getTotalSkipped(Map<String, TableMigrationStats> stats) =>
      stats.values.fold(0, (sum, s) => sum + s.skippedCount);

  int _getTotalErrors(Map<String, TableMigrationStats> stats) =>
      stats.values.fold(0, (sum, s) => sum + s.errorCount);

  /// Migrate a single table
  Future<TableMigrationStats> _migrateTable(String tableName) async {
    final stats = TableMigrationStats(tableName: tableName);

    try {
      // Fetch all rows from the table
      final rows = await database.query(tableName);
      stats.totalCount = rows.length;

      _logger.info('Found ${rows.length} rows in $tableName');

      if (rows.isEmpty) {
        _logger.info('Table $tableName is empty, skipping');
        return stats;
      }

      // Process rows in batches
      const batchSize = 50;
      var batch = database.batch();
      var batchCount = 0;

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final id = row['id'] as String;
        final jsonString = row['json'] as String;

        try {
          // Parse JSON
          final json = jsonDecode(jsonString) as Map<String, dynamic>;

          // Check if migration is needed
          final version = ModelVersionMigration.getVersion(json);

          if (version >= 2) {
            // Already migrated
            stats.skippedCount++;
            continue;
          }

          // Migrate the JSON
          final migratedJson = await _migrateJsonDocument(json, tableName);

          // Update the row
          batch.update(
            tableName,
            {
              'json': jsonEncode(migratedJson),
              'last_modified': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [id],
          );

          stats.migratedCount++;
          batchCount++;

          // Commit batch when it reaches the size limit
          if (batchCount >= batchSize) {
            await batch.commit(noResult: true);
            batch = database.batch();
            batchCount = 0;
          }
        } catch (e) {
          _logger.warning('Failed to migrate row $id in $tableName: $e');
          await _writeLog('ERROR migrating row $id in $tableName: $e');
          stats.errorCount++;
          stats.errors.add('Row $id: $e');
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit(noResult: true);
      }

      _logger.info(
        'Table $tableName: migrated=${stats.migratedCount}, '
        'skipped=${stats.skippedCount}, errors=${stats.errorCount}',
      );

      return stats;
    } catch (e, stackTrace) {
      _logger.severe('Failed to migrate table $tableName', e, stackTrace);
      throw MigrationException(
        'Failed to migrate table $tableName: $e',
        tableName: tableName,
      );
    }
  }

  /// Migrate a single JSON document
  Future<Map<String, dynamic>> _migrateJsonDocument(
    Map<String, dynamic> json,
    String tableName,
  ) async {
    // Get resource type from JSON or infer from table name
    final resourceType =
        json['resourceType'] as String? ?? _inferResourceType(tableName);

    // Get the appropriate migrator
    final migrator = MigratorRegistry.getMigrator(resourceType, 1, 2);

    if (migrator == null) {
      throw MigrationException(
        'No migrator found for resource type: $resourceType',
        tableName: tableName,
      );
    }

    // For JSON-based migration, we need to work with the JSON directly
    // The migrators expect model objects, so we:
    // 1. Deserialize v1 JSON to v1 model
    // 2. Migrate v1 model to v2 model
    // 3. Serialize v2 model back to JSON

    final v1Model = migrator.deserializeV1(json);
    final v2Model = migrator.migrate(v1Model);
    final v2Json = migrator.serializeV2(v2Model);

    return v2Json;
  }

  /// Infer resource type from table name
  String _inferResourceType(String tableName) {
    switch (tableName) {
      case 'person':
        return 'Person';
      case 'sexual_activity_type':
        return 'SexualActivityCategory';
      case 'sexual_activity_type_property':
        return 'SexualActivity';
      case 'sexual_event':
        return 'SexualEvent';
      default:
        throw MigrationException(
          'Cannot infer resource type for table: $tableName',
          tableName: tableName,
        );
    }
  }

  /// Clean up old backups (keep last N backups)
  Future<void> cleanupBackups({int keep = 5}) async {
    try {
      final dbFile = File(databasePath);
      final dbDir = dbFile.parent;

      final backups = await dbDir
          .list()
          .where((entity) => entity is File && entity.path.contains('.backup-'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      backups.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      // Delete old backups
      if (backups.length > keep) {
        for (var i = keep; i < backups.length; i++) {
          _logger.info('Deleting old backup: ${backups[i].path}');
          await backups[i].delete();
        }
      }
    } catch (e) {
      _logger.warning('Failed to clean up backups: $e');
      // Non-fatal, just log
    }
  }
}

/// Result of a migration operation
class MigrationResult {
  final bool success;
  final String? error;
  final String? backupPath;
  final Duration duration;
  final Map<String, TableMigrationStats> tableStats;

  MigrationResult({
    required this.success,
    this.error,
    this.backupPath,
    required this.duration,
    required this.tableStats,
  });

  int get totalMigrated =>
      tableStats.values.fold(0, (sum, stats) => sum + stats.migratedCount);

  int get totalErrors =>
      tableStats.values.fold(0, (sum, stats) => sum + stats.errorCount);

  int get totalSkipped =>
      tableStats.values.fold(0, (sum, stats) => sum + stats.skippedCount);

  int get totalProcessed =>
      tableStats.values.fold(0, (sum, stats) => sum + stats.totalCount);
}

/// Statistics for a table migration
class TableMigrationStats {
  final String tableName;
  int totalCount = 0;
  int migratedCount = 0;
  int skippedCount = 0;
  int errorCount = 0;
  List<String> errors = [];

  TableMigrationStats({required this.tableName});
}

/// Migration exception
class MigrationException implements Exception {
  final String message;
  final String? tableName;
  final bool isFatal;

  MigrationException(this.message, {this.tableName, this.isFatal = false});

  @override
  String toString() {
    if (tableName != null) {
      return 'MigrationException [$tableName]: $message';
    }
    return 'MigrationException: $message';
  }
}
