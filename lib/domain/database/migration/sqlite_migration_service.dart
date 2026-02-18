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

  /// Tables that may contain v1 JSON documents which need v1->v2 migration.
  static const tables = [
    'person',
    'sexual_activity_type',
    'sexual_activity_type_property',
    'sexual_event',
  ];

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
  ///
  /// This method uses a simple, conservative check:
  /// - If schema_version >= 3 AND migration_completed_at exists -> no migration needed
  /// - Otherwise, migration may be needed (return true)
  ///
  /// This avoids false positives that can cause repeated migrations and data corruption.
  Future<bool> needsMigration() async {
    try {
      await ensureMetadataTableExists();

      // Check for schema_version
      final result = await database.query(
        'database_metadata',
        where: 'key = ?',
        whereArgs: ['schema_version'],
      );

      // No schema version - check for legacy v1 database
      if (result.isEmpty) {
        final tables = await database.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'person'],
        );

        if (tables.isNotEmpty) {
          _logger.info(
            'No schema_version found but person table exists, migration needed (V1 DB)',
          );
          return true;
        }

        _logger.info('No schema_version and no person table, new DB');
        return false;
      }

      final currentSchemaVersion = int.parse(result.first['value'] as String);
      _logger.info('Current schema version: $currentSchemaVersion');

      // If schema >= 3, check for migration_completed_at marker
      if (currentSchemaVersion >= 3) {
        final migrationCompletedAt = await getMetadata(
          'migration_completed_at',
        );
        if (migrationCompletedAt != null) {
          _logger.info(
            'Migration previously completed at $migrationCompletedAt and schema >=3; no migration needed',
          );
          return false;
        }
        // Schema >= 3 but no completion marker - might be a fresh v3 DB
        // that was created but not marked as completed. Treat as no migration needed
        // to avoid corrupting data. User can manually trigger if truly needed.
        _logger.info(
          'Schema version $currentSchemaVersion >= 3 but no migration_completed_at marker found. Treating as up-to-date to avoid false-positive migration.',
        );
        return false;
      }

      // Schema < 3, migration is needed
      _logger.info(
        'Database schema version $currentSchemaVersion < 3; migration needed',
      );
      return true;
    } catch (e) {
      _logger.warning('Error checking migration status: $e');
      // If we can't determine, assume migration is needed
      return true;
    }
  }

  /// Check if JSON document migration is needed (v1 -> v2).
  /// This is separate from schema migration - JSON migration can be slow
  /// for large databases, so callers may want to show a progress UI.
  Future<bool> needsJsonMigration() async {
    try {
      // First ensure metadata table exists
      await ensureMetadataTableExists();

      // Check if we've already completed JSON migration
      final jsonMigrationCompleted = await getMetadata(
        'json_migration_completed',
      );
      if (jsonMigrationCompleted != null) {
        _logger.info('JSON migration already completed');
        return false;
      }

      // Check if there are v1 documents that need migration
      return await detectV1Documents();
    } catch (e) {
      _logger.warning('Error checking JSON migration status: $e');
      return true; // Be conservative
    }
  }

  /// Detect whether any table contains v1 JSON documents.
  /// Public method for checking migration status separately from running migration.
  ///
  /// This is more robust than just checking the version field - it also detects
  /// v2-format data that lacks a version field (e.g., from corrupted backups).
  Future<bool> detectV1Documents() async {
    try {
      for (final table in tables) {
        // If the table doesn't exist, skip it.
        final exists = await database.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', table],
        );
        if (exists.isEmpty) continue;

        // Read a small sample of rows to detect legacy JSON.
        final rows = await database.query(table, limit: 10);

        for (final row in rows) {
          final jsonString = row['json'] as String?;
          if (jsonString == null) continue;
          try {
            final doc = jsonDecode(jsonString) as Map<String, dynamic>;
            final version = ModelVersionMigration.getVersion(doc);

            // If version field exists and is current, no migration needed
            if (version == ModelVersionMigration.currentVersion) {
              continue;
            }

            // No version field (defaults to 1) - check if data is actually v2 format
            // by looking for v2-specific fields
            if (!_hasV2Format(table, doc)) {
              _logger.info(
                'Detected v$version (or no version) document in $table with v1 format -> needs migration',
              );
              return true;
            }

            // Has v2 format but no version field - this is the corrupted backup case
            // Treat as already migrated (v2 format present)
            _logger.info(
              'Document in $table has v2 format but no version field - treating as already migrated',
            );
          } catch (_) {
            // Ignore parse errors
          }
        }
      }
    } catch (e) {
      _logger.warning('Error while detecting v1 documents: $e');
      return true;
    }
    return false;
  }

  /// Check if a document has v2 format by looking for v2-specific fields
  bool _hasV2Format(String table, Map<String, dynamic> doc) {
    switch (table) {
      case 'person':
        // v2 Person has new fields like 'location', 'notes', 'isSelf'
        return doc.containsKey('isSelf') || doc.containsKey('notes');
      case 'sexual_activity_type':
        // v2 SexualActivityCategory has 'activities' (list of references) and new fields
        return doc.containsKey('activities') && doc['activities'] is List;
      case 'sexual_activity_type_property':
        // v2 SexualActivity has 'category' reference and new fields
        return doc.containsKey('category') ||
            doc.containsKey('displayCharacter');
      case 'sexual_event':
        // v2 SexualEvent has 'location', 'notes', and uses 'EventActivity' not 'SexualActivity'
        // v1 uses 'SexualActivity' objects, v2 uses 'EventActivity'
        if (doc.containsKey('location') || doc.containsKey('notes')) {
          return true;
        }
        // Check if activities are in v2 format (EventActivity has 'category' and 'participants')
        final activities = doc['activities'];
        if (activities is List && activities.isNotEmpty) {
          final firstActivity = activities.first as Map<String, dynamic>?;
          if (firstActivity != null) {
            // v2 EventActivity has 'category' and 'participants'
            // v1 SexualActivity has 'type' and 'participants'
            return firstActivity.containsKey('category');
          }
        }
        return false;
      default:
        return false;
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
  ///
  /// We must checkpoint any WAL content back into the main database file
  /// before copying to obtain a consistent, standalone snapshot. This function
  /// attempts a TRUNCATE checkpoint first and falls back to FULL. We also run
  /// a lightweight integrity check to encourage page flushes before copying.
  Future<String> createBackup() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '$databasePath.backup-$timestamp';

      _logger.info('Creating backup at: $backupPath');

      // Attempt to checkpoint WAL frames into the main database file so a plain
      // file copy yields a coherent snapshot. Use TRUNCATE (reclaims WAL file)
      // and fall back to FULL if TRUNCATE isn't supported or fails.
      try {
        await database.execute('PRAGMA wal_checkpoint(TRUNCATE)');
        _logger.info('WAL checkpoint (TRUNCATE) completed');
      } catch (e) {
        _logger.warning('WAL checkpoint (TRUNCATE) failed: $e');
        try {
          await database.execute('PRAGMA wal_checkpoint(FULL)');
          _logger.info('WAL checkpoint (FULL) completed');
        } catch (e2) {
          _logger.warning('WAL checkpoint (FULL) also failed: $e2');
        }
      }

      // Run a lightweight integrity check which can help flush caches on some
      // implementations; ignore non-fatal failures.
      try {
        await database.rawQuery('PRAGMA integrity_check');
      } catch (_) {}

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

  /// Perform the full migration from v1 -> v2 and then v2 -> v3 (if required).
  ///
  /// This method explicitly:
  /// 1. Detects whether any v1 JSON documents remain and runs v1->v2 migration
  ///    across relevant tables if necessary.
  /// 2. After JSON migrations, checks and runs schema upgrades (v2->v3) if
  ///    the DB schema_version indicates older than 3.
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

      // Helper: detect whether any table contains v1 JSON documents.
      Future<bool> _detectV1Documents() async {
        try {
          for (final table in tables) {
            // If the table doesn't exist, skip it.
            final exists = await database.query(
              'sqlite_master',
              where: 'type = ? AND name = ?',
              whereArgs: ['table', table],
            );
            if (exists.isEmpty) continue;

            // Read a small sample of rows to detect legacy JSON. We only need
            // to find one v1 document to trigger migration work.
            final rows = await database.query(table, limit: 10);

            for (final row in rows) {
              final jsonString = row['json'] as String?;
              if (jsonString == null) continue;
              try {
                final doc = jsonDecode(jsonString) as Map<String, dynamic>;
                final version = ModelVersionMigration.getVersion(doc);
                if (version < ModelVersionMigration.currentVersion) {
                  _logger.info(
                    'Detected v$version document in $table -> needs migration',
                  );
                  return true;
                }
              } catch (_) {
                // Ignore parse errors for detection; they'll be surfaced in real migration.
              }
            }
          }
        } catch (e) {
          _logger.warning('Error while detecting v1 documents: $e');
          // If detection fails, be conservative and indicate migration is required.
          return true;
        }
        return false;
      }

      // Helper: perform v1->v2 migration across the tables. This reuses the
      // existing _migrateTable implementation which handles per-table JSON
      // migration (v1 -> v2).
      Future<void> _performV1toV2Migration() async {
        for (var i = 0; i < tables.length; i++) {
          final table = tables[i];
          _logger.info('Migrating table (v1->v2): $table');
          await _writeLog('Starting migration of table: $table');

          onProgress?.call(table, i, tables.length, 'Migrating $table...');

          // If the table is missing, _migrateTable will early-return after
          // attempting to query it (and logging). Keep its stats entry to
          // summarize results.
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
      }

      // Step 1/2: Detect & perform v1 -> v2 JSON migrations if needed.
      // Note: v1 documents can exist in v2 schema, so we always check for v1 docs.
      final hasV1Docs = await _detectV1Documents();
      if (hasV1Docs) {
        _logger.info('v1 documents detected - performing v1->v2 migration');
        await _writeLog('Performing v1->v2 migrations');
        await _performV1toV2Migration();
        await _writeLog('Completed v1->v2 migrations');
        // Mark JSON migration as completed to avoid re-running
        await setMetadata(
          'json_migration_completed',
          DateTime.now().toIso8601String(),
        );
      } else {
        _logger.info('No v1 documents detected - skipping v1->v2 migration');
        await _writeLog('No v1->v2 migrations required');
      }

      // Step 3/4: After JSON migration, ensure schema upgrades (v2 -> v3) occur.
      final currentSchemaVersion =
          int.tryParse(await getMetadata('schema_version') ?? '1') ?? 1;
      _logger.info('Current DB schema version: $currentSchemaVersion');

      if (currentSchemaVersion < 3) {
        _logger.info(
          'Upgrading database schema from v$currentSchemaVersion to v3',
        );
        await _writeLog('Starting DB schema upgrade to v3');
        await _migrateV2toV3(onProgress: onProgress);
        await setMetadata('schema_version', '3');
        await _writeLog('DB schema upgraded to v3');
        // Verify the schema_version persisted to avoid repeated migration loops.
        // Some environments may not persist metadata reliably on first write,
        // so read it back and retry once if necessary.
        try {
          final persistedVersion =
              await getMetadata('schema_version') ?? 'unknown';
          _logger.info('Verifying schema_version persisted: $persistedVersion');
          await _writeLog(
            'Verifying schema_version persisted: $persistedVersion',
          );
          if (persistedVersion != '3') {
            _logger.warning(
              'schema_version verify failed (was $persistedVersion); setting again to 3',
            );
            await setMetadata('schema_version', '3');
            final recheck = await getMetadata('schema_version') ?? 'unknown';
            _logger.info('Re-verified schema_version: $recheck');
            await _writeLog('Re-verified schema_version: $recheck');
          }
        } catch (e) {
          _logger.warning('Error verifying schema_version persistence: $e');
          await _writeLog('ERROR verifying schema_version persistence: $e');
          // In the event of a verification failure we'll still continue and
          // clear the migration flag below; needsMigration() is conservative
          // and will re-run migration if the metadata truly didn't persist.
        }
      } else {
        // Ensure metadata reflects at least the current value
        await setMetadata('schema_version', currentSchemaVersion.toString());
      }

      // Ensure an index exists on sexual_event.date to speed up date queries.
      // Some older DBs may not have this index; creating it is idempotent.
      try {
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_sexual_event_date ON sexual_event(date)',
        );
        _logger.info('Ensured index idx_sexual_event_date exists');
      } catch (e) {
        _logger.warning('Failed to create/ensure idx_sexual_event_date: $e');
      }

      // Ensure clinical_event table exists for storing ClinicalEvent JSON blobs.
      // Newer app versions will use this table; create it if missing so
      // migrations and imports have a place to write data.
      try {
        await database.execute('''
          CREATE TABLE IF NOT EXISTS clinical_event (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            last_modified TEXT,
            json TEXT NOT NULL
          )
        ''');
        // Index to speed up lookups by date for calendar highlighting.
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_clinical_event_date ON clinical_event(date)',
        );
        _logger.info('Ensured clinical_event table and index exist');
      } catch (e) {
        _logger.warning('Failed to create clinical_event table or index: $e');
      }

      // Persist final migration metadata and clear the in-progress flag.
      // Wrap in a try/catch to ensure we do not throw here and to log any
      // persistence problems that could otherwise cause repeated migration
      // attempts.
      try {
        final completedAt = DateTime.now().toIso8601String();
        await setMetadata('migration_completed_at', completedAt);
        await setMetadata('migration_in_progress', 'false');

        // Also verify and log the final schema_version so callers can inspect it.
        final finalSchema = await getMetadata('schema_version') ?? 'unknown';
        _logger.info('Final schema_version after migration: $finalSchema');
        await _writeLog('Final schema_version after migration: $finalSchema');
      } catch (e) {
        _logger.warning('Failed to persist final migration metadata: $e');
        await _writeLog('ERROR persisting final migration metadata: $e');
        // Continue; needsMigration() is conservative and will re-run migration
        // only if metadata truly didn't persist. Avoid throwing here so the
        // migration process can finish its cleanup steps.
      }

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
      // Defensive: ensure the table exists before attempting to query it.
      final master = await database.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );

      if (master.isEmpty) {
        _logger.info(
          'Table $tableName does not exist, skipping migration for this table',
        );
        return stats;
      }

      // Read all rows from the table (we'll build a migrated copy and swap atomically)
      final rows = await database.query(tableName);
      stats.totalCount = rows.length;

      _logger.info('Found ${rows.length} rows in $tableName');

      if (rows.isEmpty) {
        _logger.info('Table $tableName is empty, skipping');
        return stats;
      }

      // Determine column names for the table so we can copy values into the temp table.
      final pragma = await database.rawQuery('PRAGMA table_info($tableName)');
      final cols = pragma.map((r) => r['name'] as String).toList();

      // Name for the temporary staging table used during migration
      final tmpTable = '${tableName}_migration_tmp';

      // Perform migration in a single transaction: build a migrated copy and swap
      await database.transaction((txn) async {
        // Ensure no leftover temp table exists
        await txn.execute('DROP TABLE IF EXISTS $tmpTable');

        // Create temp table with same columns (structure) and no rows
        // Using "AS SELECT ... WHERE 0" copies column names.
        await txn.execute(
          'CREATE TABLE $tmpTable AS SELECT * FROM $tableName WHERE 0',
        );

        // Prepare insert template using discovered columns
        // We'll construct a row map for txn.insert
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          final jsonString = row['json'] as String?;

          try {
            Map<String, dynamic>? migratedRowJsonMap;

            if (jsonString != null) {
              // Parse the JSON if present
              final doc = jsonDecode(jsonString) as Map<String, dynamic>;
              final version = ModelVersionMigration.getVersion(doc);

              if (version < ModelVersionMigration.currentVersion) {
                // Migrate the JSON document to v2
                final migratedJson = await _migrateJsonDocument(doc, tableName);
                migratedRowJsonMap = migratedJson;
              }
            }

            // Build the map of column->value for insertion into tmp table
            final insertMap = <String, Object?>{};
            for (final col in cols) {
              if (col == 'json') {
                // Use migrated JSON if available, otherwise original jsonString
                final value = migratedRowJsonMap != null
                    ? jsonEncode(migratedRowJsonMap)
                    : jsonString;
                insertMap['json'] = value;
              } else if (col == 'last_modified') {
                // Update last_modified to now for migrated rows; preserve for others
                if (migratedRowJsonMap != null) {
                  insertMap['last_modified'] = DateTime.now().toIso8601String();
                } else {
                  insertMap['last_modified'] = row['last_modified'];
                }
              } else {
                // Copy other columns verbatim
                insertMap[col] = row[col];
              }
            }

            // Insert into temp table (replace on conflict to be safe)
            await txn.insert(
              tmpTable,
              insertMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Update stats
            if (migratedRowJsonMap != null) {
              stats.migratedCount++;
            } else {
              stats.skippedCount++;
            }
          } catch (e) {
            // If any row fails to migrate, throw to rollback the transaction.
            _logger.warning(
              'Failed to migrate row ${row['id']} in $tableName: $e',
            );
            await _writeLog(
              'ERROR migrating row ${row['id']} in $tableName: $e',
            );
            stats.errorCount++;
            stats.errors.add('Row ${row['id']}: $e');
            throw e;
          }
        }

        // All rows migrated into temp table successfully. Now atomically swap tables.
        // Rename original table to a backup name, rename temp to original, then drop backup.
        final backupName = '${tableName}_backup_migration';
        await txn.execute('ALTER TABLE $tableName RENAME TO $backupName');
        await txn.execute('ALTER TABLE $tmpTable RENAME TO $tableName');

        // Recreate any indexes that referenced the original table may be needed.
        // The migration flow elsewhere ensures common indexes exist, but we attempt
        // to drop the backup now that the swap succeeded.
        await txn.execute('DROP TABLE IF EXISTS $backupName');
      });

      _logger.info(
        'Table $tableName: migrated=${stats.migratedCount}, '
        'skipped=${stats.skippedCount}, errors=${stats.errorCount}',
      );

      return stats;
    } catch (e, stackTrace) {
      _logger.severe('Failed to migrate table $tableName', e, stackTrace);
      // If an error occurred during the transactional swap, ensure temp/backup cleanup
      try {
        await database.execute(
          'DROP TABLE IF EXISTS ${tableName}_migration_tmp',
        );
        await database.execute(
          'DROP TABLE IF EXISTS ${tableName}_backup_migration',
        );
      } catch (_) {
        // ignore cleanup errors
      }
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

    // Ensure migrated JSON includes the version metadata so subsequent checks
    // recognize this as a v2 document.
    final v2JsonWithVersion = ModelVersionMigration.addVersion(
      v2Json,
      ModelVersionMigration.currentVersion,
    );

    return v2JsonWithVersion;
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

  /// Migrate DB schema v2 -> v3
  ///
  /// This migration:
  /// - Finds any `location` table rows and loads them into memory
  /// - For each sexual_event, if `location` is a Reference to a Location,
  ///   replaces that reference with the actual Location JSON (removing any
  ///   `id` field in the embedded Location)
  /// - Drops the standalone `location` table
  Future<void> _migrateV2toV3({ProgressCallback? onProgress}) async {
    try {
      // Check if the location table exists; if not, nothing to do.
      final tables = await database.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'location'],
      );
      if (tables.isEmpty) {
        _logger.info('No location table found; skipping v2->v3 migration');
        await _writeLog('No location table found; skipping v2->v3 migration');
        return;
      }

      // Load locations into a map for quick lookup
      final locRows = await database.query('location');
      final Map<String, Map<String, dynamic>> locationsById = {};
      for (final row in locRows) {
        final id = row['id'] as String;
        final locJson =
            jsonDecode(row['json'] as String) as Map<String, dynamic>;
        locationsById[id] = locJson;
      }

      // Iterate over sexual_event rows and embed location JSON where a Reference exists
      final eventRows = await database.query('sexual_event');
      for (var i = 0; i < eventRows.length; i++) {
        final row = eventRows[i];
        final eventId = row['id'] as String;
        try {
          final jsonMap =
              jsonDecode(row['json'] as String) as Map<String, dynamic>;
          final locField = jsonMap['location'];

          // Only handle the case where location is a Reference-like map
          if (locField is Map &&
              locField['resourceType'] == 'Location' &&
              locField['reference'] != null) {
            final refId = locField['reference'] as String;
            final locJson = locationsById[refId];
            if (locJson != null) {
              // Remove any id from the embedded location (locations in v3 are embedded
              // and do not carry a top-level id field)
              locJson.remove('id');

              // Replace the reference with the actual location JSON
              jsonMap['location'] = locJson;

              // Persist the updated sexual_event row
              await database.update(
                'sexual_event',
                {
                  'json': jsonEncode(jsonMap),
                  'last_modified': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [eventId],
              );

              await _writeLog('Embedded location $refId into event $eventId');
            } else {
              await _writeLog(
                'Location reference $refId not found for event $eventId',
              );
            }
          }
        } catch (e) {
          _logger.warning('Failed to migrate location for event $eventId: $e');
          await _writeLog('ERROR migrating event $eventId location: $e');
        }

        // Report progress if caller provided a callback
        onProgress?.call(
          'sexual_event_location_migration',
          i + 1,
          eventRows.length,
          'Migrating event locations',
        );
      }

      // After embedding locations into events, drop the standalone location table
      await database.execute('DROP TABLE IF EXISTS location');
      await _writeLog('Dropped location table after v2->v3 migration');
      // Ensure indexes for date columns on event tables to speed up date queries in v3
      try {
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_sexual_event_date ON sexual_event(date)',
        );
        _logger.info('Ensured idx_sexual_event_date exists (v3 migration)');
      } catch (e) {
        _logger.warning('Failed to create/ensure idx_sexual_event_date: $e');
      }
      try {
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_clinical_event_date ON clinical_event(date)',
        );
        _logger.info('Ensured idx_clinical_event_date exists (v3 migration)');
      } catch (e) {
        _logger.warning('Failed to create/ensure idx_clinical_event_date: $e');
      }
      _logger.info(
        'v2->v3 migration completed: embedded locations, dropped table, and ensured indexes',
      );
    } catch (e, stackTrace) {
      _logger.severe('v2->v3 migration failed', e, stackTrace);
      await _writeLog('ERROR: v2->v3 migration failed: $e');
      throw MigrationException('v2->v3 migration failed: $e', isFatal: true);
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
