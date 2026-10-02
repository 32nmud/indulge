import 'package:logging/logging.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:indulge/domain/database/database_engine.dart';
import 'package:indulge/services/security/encryption_key_service.dart';

/// Centralized service for managing database connections.
///
/// This service handles:
/// - Encryption key management
/// - Database connection lifecycle
/// - Ensuring encryption is applied before opening connections
class DatabaseConnectionService {
  static final Logger _logger = Logger('DatabaseConnectionService');

  static DatabaseConnectionService? _instance;
  static Database? _database;

  final EncryptionKeyService _keyService;

  DatabaseConnectionService._({EncryptionKeyService? keyService})
    : _keyService = keyService ?? EncryptionKeyService();

  /// Gets the singleton instance of DatabaseConnectionService.
  static DatabaseConnectionService get instance {
    _instance ??= DatabaseConnectionService._();
    return _instance!;
  }

  /// Initializes the database connection.
  ///
  /// This should be called early in app startup, after PIN verification
  /// (if PIN is enabled).
  ///
  /// [encryptionKey] - Optional explicit key. If not provided, will be fetched
  ///                   from secure storage.
  Future<Database> initialize({String? encryptionKey}) async {
    if (_database != null) {
      return _database!;
    }

    _logger.info('Initializing database connection...');

    // Get encryption key if not provided
    final key = encryptionKey ?? await _keyService.getOrCreateEncryptionKey();

    // Open the encrypted database
    _database = await DatabaseEngine.buildLocalConnection(encryptionKey: key);

    _logger.info('Database connection initialized successfully');
    return _database!;
  }

  /// Gets the current database connection.
  /// Throws an exception if not initialized.
  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Checks if the database connection is initialized.
  bool get isInitialized => _database != null;

  /// Closes the database connection.
  /// Useful for testing or when resetting app data.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.info('Database connection closed');
    }
  }

  /// Resets the service - closes connection and clears instance.
  /// Used when user resets all app data.
  Future<void> reset() async {
    await close();
    _instance = null;
  }
}
