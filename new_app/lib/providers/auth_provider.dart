import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('logged_in_user_id');
    if (userId != null) {
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.authenticateUser(
        username.trim(), password,
      );
      if (user != null) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('logged_in_user_id', user.id!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid username or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = await DatabaseHelper.instance.getUser(username.trim());
      if (existing != null) {
        _error = 'Username already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = UserModel(
        username: username.trim(),
        password: password,
        displayName: displayName.trim(),
      );
      final id = await DatabaseHelper.instance.createUser(user);
      _currentUser = user.copyWith(id: id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('logged_in_user_id', id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateCurrency(String currency) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(currency: currency);
    await DatabaseHelper.instance.updateUser(_currentUser!);
    notifyListeners();
  }

  Future<void> updateBudget(double budget) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(monthlyBudget: budget);
    await DatabaseHelper.instance.updateUser(_currentUser!);
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(displayName: name);
    await DatabaseHelper.instance.updateUser(_currentUser!);
    notifyListeners();
  }

  Future<void> updateAvatar(String emoji) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(avatarEmoji: emoji);
    await DatabaseHelper.instance.updateUser(_currentUser!);
    notifyListeners();
  }

  Future<void> updateProfilePhoto(String? path) async {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      username: _currentUser!.username,
      password: _currentUser!.password,
      displayName: _currentUser!.displayName,
      currency: _currentUser!.currency,
      monthlyBudget: _currentUser!.monthlyBudget,
      avatarEmoji: _currentUser!.avatarEmoji,
      profilePhotoPath: path,
      pin: _currentUser!.pin,
      createdAt: _currentUser!.createdAt,
    );
    await DatabaseHelper.instance.updateUser(_currentUser!);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
