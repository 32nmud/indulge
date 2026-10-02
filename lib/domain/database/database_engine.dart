import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'database_seed.dart';
import 'migration/sqlite_migration_service.dart';

class DatabaseEngine {
  static final Logger _logger = Logger('DatabaseEngine');

  /// Builds a local SQLite database connection with encryption support.
  ///
  /// [encryptionKey] - If provided, opens the database with SQLCipher encryption.
  ///                   If null, opens in compatibility mode (for migration from unencrypted).
  static Future<Database> buildLocalConnection({String? encryptionKey}) async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');

    final openFuture = encryptionKey != null
        ? openDatabase(
            dbPath,
            password: encryptionKey,
            onCreate: (db, version) => _onCreate(db, version),
            onUpgrade: (db, oldVersion, newVersion) =>
                _onUpgrade(db, oldVersion, newVersion),
            version: 3,
          )
        : openDatabase(
            dbPath,
            onCreate: (db, version) => _onCreate(db, version),
            onUpgrade: (db, oldVersion, newVersion) =>
                _onUpgrade(db, oldVersion, newVersion),
            version: 3,
          );

    return await openFuture;
  }

  static Future<void> _onCreate(Database db, int version) async {
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
      databasePath: await dbPath,
    );
    await migrationService.ensureMetadataTableExists();
    await migrationService.setMetadata('schema_version', '3');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
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
  }

  /// Helper to get dbPath for migration service
  static Future<String> get dbPath async =>
      join(await getDatabasesPath(), 'indulge.db');

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

    // Also check whether JSON (v1->v2) migration is required even if schema metadata
    // indicates no migration. It's possible the DB schema is at v3 but some JSON
    // payloads still need to be migrated; in that case we must run the JSON migration.
    final jsonMigrationNeeded = await migrationService.needsJsonMigration();

    if (!migrationNeededByMeta) {
      if (jsonMigrationNeeded) {
        _logger.info(
          'Schema metadata indicates up-to-date, but JSON documents require migration. Forcing migration.',
        );
        // fall through to perform migration
      } else {
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

  /// Checks if the existing database is encrypted.
  /// Returns true if the database appears to be encrypted (requires password),
  /// false if it can be opened without a password.
  static Future<bool> isDatabaseEncrypted() async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      return false; // No database yet
    }

    // Try to open without password - if it works, DB is unencrypted
    // We use a try-catch with a timeout to handle native exceptions
    try {
      final db = await openDatabase(dbPath);
      await db.close();
      return false;
    } catch (e) {
      // Check for any exception - if we can't open without password, assume encrypted
      // The SQLCipher library throws native exceptions that may not be caught normally
      _logger.info('Could not open DB without password: $e');
      return true;
    }
  }

  /// Migrates an unencrypted database to encrypted format.
  /// Creates new encrypted DB, exports data via raw SQL, replaces original.
  ///
  /// Steps:
  /// 1. Read all data from unencrypted DB
  /// 2. Delete unencrypted DB file
  /// 3. Create new encrypted DB (without onCreate - just open fresh)
  /// 4. Create tables manually in encrypted DB
  /// 5. Copy all data to encrypted DB
  ///
  /// [encryptionKey] - The new encryption key to use
  static Future<void> encryptDatabase(String encryptionKey) async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');
    final backupPath = '${dbPath}.unencrypted.backup';

    _logger.info('Starting database encryption migration...');

    // Step 1: Read all data from unencrypted DB
    final unencryptedDb = await openDatabase(dbPath);

    // Get list of tables (excluding sqlite internal tables)
    final tablesResult = await unencryptedDb.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final tableNames = tablesResult
        .map((t) => t['name'] as String)
        .where((name) => !name.startsWith('sqlite_'))
        .toList();

    // Export all data from each table
    final Map<String, List<Map<String, Object?>>> allData = {};
    for (final tableName in tableNames) {
      allData[tableName] = await unencryptedDb.query(tableName);
      _logger.info(
        'Exported ${allData[tableName]!.length} rows from $tableName',
      );
    }

    await unencryptedDb.close();

    // Step 2: Backup and delete unencrypted DB
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(backupPath);
      await dbFile.delete();
      // Delete related files
      for (final suffix in ['', '-journal', '-wal', '-shm']) {
        final f = File('$dbPath$suffix');
        if (await f.exists()) await f.delete();
      }
      _logger.info('Deleted unencrypted DB, backup at $backupPath');
    }

    try {
      // Step 3: Create new encrypted DB WITHOUT onCreate (we'll add tables manually)
      final encryptedDb = await openDatabase(
        dbPath,
        password: encryptionKey,
        version: 3, // Use version 3 to match app expectation
      );

      // Step 4: Create tables using the original schema
      // Load schema from asset file (which has correct PRIMARY KEY definitions)
      final schemaContent = await rootBundle.loadString(
        'assets/sql/schema.sql',
      );
      final schemaStatements = schemaContent
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (final statement in schemaStatements) {
        await encryptedDb.execute(statement);
      }

      // Step 5: Import all data into encrypted DB
      // Skip android_metadata - it's Android-specific and not in our schema
      for (final tableName in tableNames) {
        if (tableName == 'android_metadata') continue;

        final data = allData[tableName];
        if (data != null && data.isNotEmpty) {
          final batch = encryptedDb.batch();
          for (final row in data) {
            // Filter out any null values that might cause issues
            final cleanRow = Map<String, Object?>.from(row)
              ..removeWhere((key, value) => value == null && key != 'id');
            batch.insert(tableName, cleanRow);
          }
          await batch.commit(noResult: true);
          _logger.info('Imported ${data.length} rows into $tableName');
        }
      }

      await encryptedDb.close();

      // Verify encryption works
      final verifyDb = await openDatabase(dbPath, password: encryptionKey);
      await verifyDb.close();

      // Delete backup
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      _logger.info('Database encryption migration completed successfully');
    } catch (e) {
      _logger.severe('Encryption migration failed: $e');
      // Restore from backup
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.rename(dbPath);
        _logger.info('Restored from backup');
      }
      rethrow;
    }
  }

  /// Checks if the database needs to be encrypted (exists but unencrypted).
  static Future<bool> needsEncryption() async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      return false; // No database yet - will be created encrypted
    }

    return await isDatabaseEncrypted() == false;
  }
}
