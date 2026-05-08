import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/savings_goal_model.dart';

class GoalsProvider with ChangeNotifier {
  List<SavingsGoalModel> _goals = [];
  bool _isLoading = false;
  int? _userId;

  List<SavingsGoalModel> get goals => _goals;
  List<SavingsGoalModel> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<SavingsGoalModel> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  bool get isLoading => _isLoading;

  int get totalBadges {
    int count = 0;
    for (final g in _goals) {
      if (g.isCompleted) count += 4; // All badges
      else if (g.progress >= 0.75) count += 3;
      else if (g.progress >= 0.50) count += 2;
      else if (g.progress >= 0.25) count += 1;
    }
    return count;
  }

  void setUserId(int userId) {
    _userId = userId;
  }

  Future<void> loadGoals() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await DatabaseHelper.instance.getSavingsGoals(_userId!);
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addGoal(SavingsGoalModel goal) async {
    try {
      final id = await DatabaseHelper.instance.createSavingsGoal(goal);
      _goals.add(goal.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding goal: $e');
      return false;
    }
  }

  Future<bool> updateGoal(SavingsGoalModel goal) async {
    try {
      await DatabaseHelper.instance.updateSavingsGoal(goal);
      final idx = _goals.indexWhere((g) => g.id == goal.id);
      if (idx >= 0) _goals[idx] = goal;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating goal: $e');
      return false;
    }
  }

  Future<bool> addSavings(int goalId, double amount) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return false;
    final goal = _goals[idx];
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    return await updateGoal(updated);
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await DatabaseHelper.instance.deleteSavingsGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      return false;
    }
  }

  void clear() {
    _goals = [];
    _userId = null;
    notifyListeners();
  }
}
