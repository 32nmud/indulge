import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing the database encryption key.
/// The key is randomly generated and stored securely using platform keychain.
///
/// Key is stored in flutter_secure_storage which uses:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (AES-256)
class EncryptionKeyService {
  static const String _keyStorageKey = 'indulge_db_encryption_key';
  static const String _pinHashKey = 'indulge_pin_hash';
  static const String _pinSaltKey = 'indulge_pin_salt';
  static const String _pinEnabledKey = 'indulge_pin_enabled';
  static const String _encryptionCompletedKey = 'indulge_encryption_completed';

  final FlutterSecureStorage _secureStorage;
  final Random _random = Random.secure();

  EncryptionKeyService({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  /// Generates a cryptographically secure random 256-bit key.
  /// Returns the key as a base64-encoded string (44 characters).
  String _generateRandomKey() {
    final values = List<int>.generate(32, (i) => _random.nextInt(256));
    return base64Encode(values);
  }

  /// Gets the existing encryption key or generates a new one if none exists.
  /// This should be called only after user has authenticated (PIN or no PIN required).
  Future<String> getOrCreateEncryptionKey() async {
    String? key = await _secureStorage.read(key: _keyStorageKey);
    if (key == null) {
      key = _generateRandomKey();
      await _secureStorage.write(key: _keyStorageKey, value: key);
    }
    return key;
  }

  /// Marks encryption as completed (called after successful migration).
  Future<void> markEncryptionCompleted() async {
    await _secureStorage.write(key: _encryptionCompletedKey, value: 'true');
  }

  /// Checks if database encryption has been completed.
  Future<bool> isEncryptionCompleted() async {
    final value = await _secureStorage.read(key: _encryptionCompletedKey);
    return value == 'true';
  }

  /// Checks if an encryption key already exists.
  Future<bool> hasEncryptionKey() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    return key != null;
  }

  /// Deletes the encryption key (used when resetting app data).
  Future<void> deleteEncryptionKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }

  /// Generates a random salt for PIN hashing.
  String _generateSalt() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));
    return base64Encode(values);
  }

  /// Hashes a PIN with a salt using SHA-256.
  /// Returns the hash as a hex string.
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Checks if a PIN has been set.
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Checks if PIN protection is enabled.
  Future<bool> isPinEnabled() async {
    final enabled = await _secureStorage.read(key: _pinEnabledKey);
    return enabled == 'true';
  }

  /// Sets a new PIN. Generates a salt and stores the hashed PIN.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _pinEnabledKey, value: 'true');
  }

  /// Verifies if the entered PIN matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    final salt = await _secureStorage.read(key: _pinSaltKey);
    final storedHash = await _secureStorage.read(key: _pinHashKey);

    if (salt == null || storedHash == null) {
      return false;
    }

    final inputHash = _hashPin(pin, salt);
    return inputHash == storedHash;
  }

  /// Disables PIN protection (does not delete the PIN, just disables it).
  Future<void> disablePin() async {
    await _secureStorage.write(key: _pinEnabledKey, value: 'false');
  }

  /// Enables PIN protection.
  Future<void> enablePin() async {
    await _secureStorage.write(key: _pinEnabledKey, value: 'true');
  }

  /// Deletes the stored PIN entirely (for reset scenarios).
  Future<void> deletePin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _secureStorage.write(key: _pinEnabledKey, value: 'false');
  }

  /// Clears all security data (encryption key and PIN).
  /// Used when user chooses to reset all app data.
  Future<void> clearAllSecurityData() async {
    await deleteEncryptionKey();
    await deletePin();
  }
}
