import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
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
        await migrationService.setMetadata('schema_version', '2');
      },
      version: 1,
    );

    return database;
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

    if (!await migrationService.needsMigration()) {
      _logger.info('No migration needed');
      return null;
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
