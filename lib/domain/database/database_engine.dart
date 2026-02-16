import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_seed.dart';
import 'migration/sqlite_migration_service.dart';

class DatabaseEngine {
  static final Logger _logger = Logger('DatabaseEngine');

  /// Builds a local SQLite database connection and checks for needed migrations
  static Future<Database> buildLocalConnection() async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');

    final database = await openDatabase(
      dbPath,
      onCreate: (db, version) async {
        // Load the full SQL schema from the bundled asset
        final schemaFile = await rootBundle.loadString('assets/sql/schema.sql');
        final DatabaseSeed seeder = DatabaseSeed(db: db);

        // SQLite in sqflite only supports a single statement per execute call.
        // Split the file into individual statements and execute them one by one.
        final statements = schemaFile
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final batch = db.batch();
        for (var stmt in statements) {
          batch.execute(stmt);
        }
        await batch.commit(noResult: true);

        await seeder.loadSeeds();

        // Set initial schema version for new databases
        final migrationService = SQLiteMigrationService(
          database: db,
          databasePath: dbPath,
        );
        await migrationService.ensureMetadataTableExists();
        await migrationService.setMetadata('schema_version', '3');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle database schema upgrades (e.g., v2 -> v3)
        // Load the full SQL schema from the bundled asset
        final schemaFile = await rootBundle.loadString('assets/sql/schema.sql');

        // Only apply schema changes for new tables/columns that don't exist
        // This is a simplified approach - in production you might want more granular migration
        final statements = schemaFile
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        // Get list of existing tables
        final existingTables = await db.query(
          'sqlite_master',
          where: 'type = ?',
          whereArgs: ['table'],
        );
        final existingTableNames = existingTables
            .map((t) => t['name'] as String)
            .toSet();

        // Execute only statements for new tables
        final batch = db.batch();
        for (var stmt in statements) {
          // Check if this CREATE TABLE statement is for a new table
          final tableNameMatch = RegExp(
            r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)',
            caseSensitive: false,
          ).firstMatch(stmt);
          if (tableNameMatch != null) {
            final tableName = tableNameMatch.group(1);
            if (tableName != null && !existingTableNames.contains(tableName)) {
              batch.execute(stmt);
            }
          }
        }
        await batch.commit(noResult: true);

        _logger.info('Database upgraded from v$oldVersion to v$newVersion');
      },
      version: 3,
    );

    return database;
  }

  /// Performs schema-only upgrade (creates new tables).
  /// Called from onUpgrade callback to create missing tables.
  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _performSchemaUpgrade(db);
  }

  /// Internal: performs the actual schema upgrade by creating missing tables
  static Future<void> _performSchemaUpgrade(Database db) async {
    final schemaFile = await rootBundle.loadString('assets/sql/schema.sql');
    final statements = schemaFile
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Get list of existing tables
    final existingTables = await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final existingTableNames = existingTables
        .map((t) => t['name'] as String)
        .toSet();

    // Execute only statements for new tables
    final batch = db.batch();
    for (var stmt in statements) {
      final tableNameMatch = RegExp(
        r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)',
        caseSensitive: false,
      ).firstMatch(stmt);
      if (tableNameMatch != null) {
        final tableName = tableNameMatch.group(1);
        if (tableName != null && !existingTableNames.contains(tableName)) {
          batch.execute(stmt);
        }
      }
    }
    await batch.commit(noResult: true);
  }

  /// Checks if migration is needed for an existing database
  static Future<bool> needsMigration(Database database, String dbPath) async {
    final migrationService = SQLiteMigrationService(
      database: database,
      databasePath: dbPath,
    );

    return await migrationService.needsMigration();
  }

  /// Gets the current schema version of the database
  static Future<int> getSchemaVersion(Database database, String dbPath) async {
    final migrationService = SQLiteMigrationService(
      database: database,
      databasePath: dbPath,
    );

    return await migrationService.getCurrentSchemaVersion();
  }

  /// Check if JSON document migration (v1 -> v2) is needed.
  /// Returns true if there are legacy v1 JSON documents that need to be migrated.
  /// This can be slow for large databases, so callers may want to show a progress UI.
  static Future<bool> needsJsonMigration(
    Database database,
    String dbPath,
  ) async {
    final migrationService = SQLiteMigrationService(
      database: database,
      databasePath: dbPath,
    );

    return await migrationService.needsJsonMigration();
  }

  /// Performs migration if needed
  /// Returns null if no migration was needed, or the MigrationResult if migration was performed
  static Future<MigrationResult?> migrateIfNeeded(
    Database database,
    String dbPath, {
    ProgressCallback? onProgress,
  }) async {
    final migrationService = SQLiteMigrationService(
      database: database,
      databasePath: dbPath,
    );

    // First check metadata-based migration requirement.
    final migrationNeededByMeta = await migrationService.needsMigration();

    if (!migrationNeededByMeta) {
      // Defensive check: even if metadata says up-to-date, ensure critical v2 tables exist.
      // If a required table is missing (e.g. clinical_event), force migration to run.
      try {
        final tables = await database.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'clinical_event'],
        );

        if (tables.isEmpty) {
          _logger.warning(
            'Schema metadata indicates no migration needed, but `clinical_event` table is missing. Forcing migration.',
          );
          // fall through to perform migration
        } else {
          _logger.info('No migration needed');
          return null;
        }
      } catch (e) {
        _logger.warning(
          'Error checking for clinical_event table presence: $e. Forcing migration as a defensive measure.',
        );
        // fall through to perform migration
      }
    }

    _logger.info('Migration needed, starting migration...');
    final result = await migrationService.migrate(onProgress: onProgress);

    if (result.success) {
      _logger.info('Migration completed successfully');
      // Clean up old backups
      await migrationService.cleanupBackups();
    } else {
      _logger.severe('Migration failed: ${result.error}');
    }

    return result;
  }
}
