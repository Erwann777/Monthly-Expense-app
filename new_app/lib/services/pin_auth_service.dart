import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages PIN authentication, biometric settings, and backup codes.
/// All sensitive data (hashed PIN, backup codes) is stored via flutter_secure_storage.
class PinAuthService {
  static const _baseKeyPinHash = 'pin_hash';
  static const _baseKeyPinSet = 'pin_is_set';
  static const _baseKeyBackupCode = 'backup_code';
  static const _baseKeyFailedAttempts = 'failed_attempts';
  static const _baseKeyLockoutUntil = 'lockout_until';

  Future<String> _key(String base) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('logged_in_user_id') ?? 0;
    return 'user_${userId}_$base';
  }

  static const int maxFailedAttempts = 5;
  static const int lockoutDurationSeconds = 30;

  final FlutterSecureStorage _storage;

  PinAuthService({
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage();

  // ─── PIN Management ───

  /// Hash a PIN using SHA-256 with a fixed salt for consistency.
  String _hashPin(String pin) {
    final bytes = utf8.encode('expense_tracker_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  /// Check if PIN has been set up.
  Future<bool> isPinSet() async {
    final val = await _storage.read(key: await _key(_baseKeyPinSet));
    return val == 'true';
  }

  /// Set a new PIN. Returns the generated backup code.
  Future<String> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: await _key(_baseKeyPinHash), value: hash);
    await _storage.write(key: await _key(_baseKeyPinSet), value: 'true');
    await _resetFailedAttempts();

    // Generate and store backup code
    final backupCode = _generateBackupCode();
    await _storage.write(key: await _key(_baseKeyBackupCode), value: backupCode);

    return backupCode;
  }

  /// Verify a PIN against the stored hash.
  Future<bool> verifyPin(String pin) async {
    // Check lockout
    if (await _isLockedOut()) return false;

    final storedHash = await _storage.read(key: await _key(_baseKeyPinHash));
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = storedHash == inputHash;

    if (isValid) {
      await _resetFailedAttempts();
    } else {
      await _incrementFailedAttempts();
    }

    return isValid;
  }

  /// Change PIN (requires old PIN verification first).
  Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;

    final hash = _hashPin(newPin);
    await _storage.write(key: await _key(_baseKeyPinHash), value: hash);
    return true;
  }

  /// Remove PIN and all auth data.
  Future<void> clearPin() async {
    await _storage.delete(key: await _key(_baseKeyPinHash));
    await _storage.delete(key: await _key(_baseKeyPinSet));
    await _storage.delete(key: await _key(_baseKeyBackupCode));
    await _resetFailedAttempts();
  }

  // ─── Backup Code ───

  String _generateBackupCode() {
    final random = Random.secure();
    final segments = List.generate(3, (_) {
      return (random.nextInt(9000) + 1000).toString();
    });
    return segments.join('-');
  }

  Future<String?> getBackupCode() async {
    return await _storage.read(key: await _key(_baseKeyBackupCode));
  }

  Future<bool> verifyBackupCode(String code) async {
    final stored = await _storage.read(key: await _key(_baseKeyBackupCode));
    if (stored == null) return false;
    return stored == code.trim();
  }

  /// Reset PIN using backup code. Returns new backup code on success.
  Future<String?> resetPinWithBackup(String backupCode, String newPin) async {
    final isValid = await verifyBackupCode(backupCode);
    if (!isValid) return null;

    final hash = _hashPin(newPin);
    await _storage.write(key: await _key(_baseKeyPinHash), value: hash);
    await _resetFailedAttempts();

    // Generate new backup code
    final newBackupCode = _generateBackupCode();
    await _storage.write(key: await _key(_baseKeyBackupCode), value: newBackupCode);

    return newBackupCode;
  }



  Future<int> getFailedAttempts() async {
    final val = await _storage.read(key: await _key(_baseKeyFailedAttempts));
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> _incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    final next = current + 1;
    await _storage.write(key: await _key(_baseKeyFailedAttempts), value: next.toString());

    if (next >= maxFailedAttempts) {
      final lockUntil = DateTime.now()
          .add(const Duration(seconds: lockoutDurationSeconds));
      await _storage.write(
        key: await _key(_baseKeyLockoutUntil),
        value: lockUntil.toIso8601String(),
      );
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _storage.write(key: await _key(_baseKeyFailedAttempts), value: '0');
    await _storage.delete(key: await _key(_baseKeyLockoutUntil));
  }

  Future<bool> _isLockedOut() async {
    final lockStr = await _storage.read(key: await _key(_baseKeyLockoutUntil));
    if (lockStr == null) return false;

    final lockUntil = DateTime.tryParse(lockStr);
    if (lockUntil == null) return false;

    if (DateTime.now().isBefore(lockUntil)) {
      return true;
    } else {
      // Lockout expired, reset
      await _resetFailedAttempts();
      return false;
    }
  }

  Future<Duration?> getRemainingLockout() async {
    final lockStr = await _storage.read(key: await _key(_baseKeyLockoutUntil));
    if (lockStr == null) return null;

    final lockUntil = DateTime.tryParse(lockStr);
    if (lockUntil == null) return null;

    final remaining = lockUntil.difference(DateTime.now());
    if (remaining.isNegative) {
      await _resetFailedAttempts();
      return null;
    }
    return remaining;
  }

  /// Wipe all secure storage (for "Forgot PIN - Clear Data" flow).
  Future<void> clearAllData() async {
    await _storage.delete(key: await _key(_baseKeyPinHash));
    await _storage.delete(key: await _key(_baseKeyPinSet));
    await _storage.delete(key: await _key(_baseKeyBackupCode));
    await _storage.delete(key: await _key(_baseKeyFailedAttempts));
    await _storage.delete(key: await _key(_baseKeyLockoutUntil));
  }
}
