import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/wallet_model.dart';

class WalletProvider with ChangeNotifier {
  List<WalletModel> _wallets = [];
  WalletModel? _selectedWallet;
  bool _isLoading = false;
  int? _userId;

  List<WalletModel> get wallets => _wallets;
  WalletModel? get selectedWallet => _selectedWallet;
  bool get isLoading => _isLoading;

  void setUserId(int userId) {
    _userId = userId;
  }

  Future<void> loadWallets() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _wallets = await DatabaseHelper.instance.getWallets(_userId!);
      if (_selectedWallet != null) {
        _selectedWallet = _wallets.firstWhere(
          (w) => w.id == _selectedWallet!.id,
          orElse: () => _wallets.isNotEmpty ? _wallets.first : _selectedWallet!,
        );
      }
    } catch (e) {
      debugPrint('Error loading wallets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectWallet(WalletModel? wallet) {
    _selectedWallet = wallet;
    notifyListeners();
  }

  Future<bool> addWallet(WalletModel wallet) async {
    try {
      final id = await DatabaseHelper.instance.createWallet(wallet);
      final newWallet = wallet.copyWith(id: id);
      _wallets.add(newWallet);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding wallet: $e');
      return false;
    }
  }

  Future<bool> updateWallet(WalletModel wallet) async {
    try {
      await DatabaseHelper.instance.updateWallet(wallet);
      final idx = _wallets.indexWhere((w) => w.id == wallet.id);
      if (idx >= 0) _wallets[idx] = wallet;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating wallet: $e');
      return false;
    }
  }

  Future<bool> deleteWallet(int id) async {
    try {
      await DatabaseHelper.instance.deleteWallet(id);
      _wallets.removeWhere((w) => w.id == id);
      if (_selectedWallet?.id == id) _selectedWallet = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting wallet: $e');
      return false;
    }
  }

  double get totalBalance {
    return _wallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  void clear() {
    _wallets = [];
    _selectedWallet = null;
    _userId = null;
    notifyListeners();
  }
}
