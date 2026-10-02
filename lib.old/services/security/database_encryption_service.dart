import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:indulge/domain/database/database_engine.dart';
import 'package:indulge/services/security/encryption_key_service.dart';

/// Service that handles database encryption migration on app startup.
///
/// This service ensures a seamless transition from unencrypted to encrypted
/// database for existing users, while new users get an encrypted database from
/// the start.
class DatabaseEncryptionService {
  final EncryptionKeyService _keyService;
  final Logger _logger = Logger('DatabaseEncryptionService');

  DatabaseEncryptionService({EncryptionKeyService? keyService})
    : _keyService = keyService ?? EncryptionKeyService();

  /// Performs encryption migration if needed.
  ///
  /// Returns true if migration was performed, false if already encrypted or
  /// no database exists.
  Future<bool> migrateIfNeeded() async {
    _logger.info('Checking if database encryption migration is needed...');

    // First check if we've already completed encryption
    final alreadyCompleted = await _keyService.isEncryptionCompleted();
    if (alreadyCompleted) {
      _logger.info('Encryption already completed previously, skipping');
      return false;
    }

    // Check if database exists
    final dbPath = join(await getDatabasesPath(), 'indulge.db');
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      _logger.info('No database exists yet - will be created encrypted');
      return false;
    }

    // Check if already encrypted
    final isEncrypted = await DatabaseEngine.isDatabaseEncrypted();
    if (isEncrypted) {
      _logger.info('Database is already encrypted');
      // Mark as completed even if it was done externally
      await _keyService.markEncryptionCompleted();
      return false;
    }

    // Need to encrypt
    _logger.info('Migrating unencrypted database to encrypted format...');

    // Get or create the encryption key
    final encryptionKey = await _keyService.getOrCreateEncryptionKey();

    // Perform the in-place encryption migration
    await DatabaseEngine.encryptDatabase(encryptionKey);

    // Mark as completed
    await _keyService.markEncryptionCompleted();

    _logger.info('Database encryption migration completed successfully');
    return true;
  }

  /// Gets the encryption key for opening the database.
  ///
  /// Should be called after authentication (PIN verification) if PIN is enabled.
  Future<String> getEncryptionKey() async {
    return await _keyService.getOrCreateEncryptionKey();
  }

  /// Checks if the database is currently encrypted.
  Future<bool> isDatabaseEncrypted() async {
    return await DatabaseEngine.isDatabaseEncrypted();
  }
}
