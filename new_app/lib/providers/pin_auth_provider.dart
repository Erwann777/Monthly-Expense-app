import 'package:flutter/material.dart';
import '../services/pin_auth_service.dart';

/// Provider that manages the PIN/biometric authentication state.
class PinAuthProvider with ChangeNotifier {
  final PinAuthService _service = PinAuthService();

  bool _isPinSet = false;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  int _failedAttempts = 0;
  Duration? _remainingLockout;
  String? _error;

  // Getters
  bool get isPinSet => _isPinSet;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  int get failedAttempts => _failedAttempts;
  Duration? get remainingLockout => _remainingLockout;
  String? get error => _error;
  bool get isLockedOut =>
      _remainingLockout != null && !_remainingLockout!.isNegative;

  PinAuthService get service => _service;

  /// Initialize the provider – load all stored state.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _isPinSet = await _service.isPinSet();
    _failedAttempts = await _service.getFailedAttempts();
    _remainingLockout = await _service.getRemainingLockout();

    _isLoading = false;
    notifyListeners();
  }

  /// Set a new PIN. Returns the backup code.
  Future<String> setupPin(String pin) async {
    final backupCode = await _service.setPin(pin);
    _isPinSet = true;
    _error = null;
    notifyListeners();
    return backupCode;
  }

  /// Verify PIN for unlock.
  Future<bool> verifyPin(String pin) async {
    _error = null;

    // Check lockout first
    _remainingLockout = await _service.getRemainingLockout();
    if (isLockedOut) {
      _error = 'Too many attempts. Try again later.';
      notifyListeners();
      return false;
    }

    final result = await _service.verifyPin(pin);
    _failedAttempts = await _service.getFailedAttempts();
    _remainingLockout = await _service.getRemainingLockout();

    if (result) {
      _isAuthenticated = true;
      _failedAttempts = 0;
      _error = null;
    } else {
      final remaining = PinAuthService.maxFailedAttempts - _failedAttempts;
      if (remaining > 0) {
        _error = 'Incorrect PIN. $remaining attempt${remaining == 1 ? '' : 's'} remaining.';
      } else {
        _error = 'Too many attempts. Try again later.';
      }
    }

    notifyListeners();
    return result;
  }



  /// Change PIN (requires old PIN).
  Future<bool> changePin(String oldPin, String newPin) async {
    final result = await _service.changePin(oldPin, newPin);
    if (!result) {
      _error = 'Current PIN is incorrect.';
    } else {
      _error = null;
    }
    notifyListeners();
    return result;
  }

  /// Reset PIN using backup code. Returns new backup code.
  Future<String?> resetPinWithBackup(String backupCode, String newPin) async {
    final newCode = await _service.resetPinWithBackup(backupCode, newPin);
    if (newCode != null) {
      _isAuthenticated = true;
      _failedAttempts = 0;
      _remainingLockout = null;
      _error = null;
    } else {
      _error = 'Invalid backup code.';
    }
    notifyListeners();
    return newCode;
  }

  /// Get the backup code for display.
  Future<String?> getBackupCode() async {
    return await _service.getBackupCode();
  }

  /// Clear PIN and all auth data (for "forgot PIN - clear data" flow).
  Future<void> clearAllAuthData() async {
    await _service.clearAllData();
    _isPinSet = false;
    _isAuthenticated = false;
    _failedAttempts = 0;
    _remainingLockout = null;
    _error = null;
    notifyListeners();
  }

  /// Lock the app (e.g. when backgrounded).
  void lock() {
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh lockout state (for countdown timer).
  Future<void> refreshLockout() async {
    _remainingLockout = await _service.getRemainingLockout();
    _failedAttempts = await _service.getFailedAttempts();
    if (!isLockedOut && _failedAttempts >= PinAuthService.maxFailedAttempts) {
      _failedAttempts = 0;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
