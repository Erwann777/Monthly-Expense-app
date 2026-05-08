import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense_model.dart';
import '../models/recurring_expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _todayExpenses = [];
  List<ExpenseModel> _monthlyExpenses = [];
  List<ExpenseModel> _last7DaysExpenses = [];
  List<RecurringExpenseModel> _recurringExpenses = [];
  Map<String, double> _categoryTotals = {};
  Map<String, double> _incomeCategoryTotals = {};
  List<Map<String, dynamic>> _dailyTotals = [];
  double _monthlyTotal = 0;
  double _monthlyIncomeTotal = 0;
  double _previousMonthTotal = 0;
  double _todayTotal = 0;
  bool _isLoading = false;
  int? _userId;

  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get todayExpenses => _todayExpenses;
  List<ExpenseModel> get monthlyExpenses => _monthlyExpenses;
  List<ExpenseModel> get last7DaysExpenses => _last7DaysExpenses;
  List<RecurringExpenseModel> get recurringExpenses => _recurringExpenses;
  Map<String, double> get categoryTotals => _categoryTotals;
  Map<String, double> get incomeCategoryTotals => _incomeCategoryTotals;
  List<Map<String, dynamic>> get dailyTotals => _dailyTotals;
  double get monthlyTotal => _monthlyTotal;
  double get monthlyIncomeTotal => _monthlyIncomeTotal;
  double get previousMonthTotal => _previousMonthTotal;
  double get todayTotal => _todayTotal;
  bool get isLoading => _isLoading;

  // Net balance for the month (income - expense)
  double get monthlyNetBalance => _monthlyIncomeTotal - _monthlyTotal;

  // Only expense items from today
  List<ExpenseModel> get todayExpenseOnly => _todayExpenses.where((e) => e.isExpense).toList();
  List<ExpenseModel> get todayIncomeOnly => _todayExpenses.where((e) => e.isIncome).toList();

  // Monthly filtered lists
  List<ExpenseModel> get monthlyExpenseOnly => _monthlyExpenses.where((e) => e.isExpense).toList();
  List<ExpenseModel> get monthlyIncomeOnly => _monthlyExpenses.where((e) => e.isIncome).toList();

  double get monthOverMonthChange {
    if (_previousMonthTotal == 0) return 0;
    return ((_monthlyTotal - _previousMonthTotal) / _previousMonthTotal * 100);
  }

  void setUserId(int userId) {
    _userId = userId;
  }

  Future<void> loadExpenses() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      _expenses = await DatabaseHelper.instance.getExpenses(_userId!);
      _todayExpenses = await DatabaseHelper.instance.getTodayExpenses(_userId!);
      _last7DaysExpenses = await DatabaseHelper.instance.getLast7DaysExpenses(_userId!);
      _monthlyExpenses = await DatabaseHelper.instance.getExpensesByMonth(
        _userId!, now.year, now.month,
      );
      _monthlyTotal = await DatabaseHelper.instance.getMonthlyExpense(
        _userId!, now.year, now.month,
      );
      _monthlyIncomeTotal = await DatabaseHelper.instance.getMonthlyIncome(
        _userId!, now.year, now.month,
      );
      // Previous month
      final prevMonth = DateTime(now.year, now.month - 1);
      _previousMonthTotal = await DatabaseHelper.instance.getMonthlyExpense(
        _userId!, prevMonth.year, prevMonth.month,
      );
      _categoryTotals = await DatabaseHelper.instance.getCategoryTotals(
        _userId!, now.year, now.month, type: 'expense',
      );
      _incomeCategoryTotals = await DatabaseHelper.instance.getCategoryTotals(
        _userId!, now.year, now.month, type: 'income',
      );
      _dailyTotals = await DatabaseHelper.instance.getDailyTotals(_userId!, 7);
      _todayTotal = _todayExpenses.where((e) => e.isExpense).fold(0.0, (sum, e) => sum + e.amount);

      // Load recurring
      _recurringExpenses = await DatabaseHelper.instance.getRecurringExpenses(_userId!);
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthExpenses(int year, int month) async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _monthlyExpenses = await DatabaseHelper.instance.getExpensesByMonth(
        _userId!, year, month,
      );
      _categoryTotals = await DatabaseHelper.instance.getCategoryTotals(
        _userId!, year, month, type: 'expense',
      );
      _incomeCategoryTotals = await DatabaseHelper.instance.getCategoryTotals(
        _userId!, year, month, type: 'income',
      );
      _monthlyTotal = await DatabaseHelper.instance.getMonthlyExpense(
        _userId!, year, month,
      );
      _monthlyIncomeTotal = await DatabaseHelper.instance.getMonthlyIncome(
        _userId!, year, month,
      );
    } catch (e) {
      debugPrint('Error loading month expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Date Range Support ───
  List<ExpenseModel> _rangeExpenses = [];
  Map<String, double> _rangeCategoryTotals = {};
  Map<String, double> _rangeIncomeCategoryTotals = {};
  double _rangeExpenseTotal = 0;
  double _rangeIncomeTotal = 0;

  List<ExpenseModel> get rangeExpenses => _rangeExpenses;
  Map<String, double> get rangeCategoryTotals => _rangeCategoryTotals;
  Map<String, double> get rangeIncomeCategoryTotals => _rangeIncomeCategoryTotals;
  double get rangeExpenseTotal => _rangeExpenseTotal;
  double get rangeIncomeTotal => _rangeIncomeTotal;
  List<ExpenseModel> get rangeExpenseOnly => _rangeExpenses.where((e) => e.isExpense).toList();
  List<ExpenseModel> get rangeIncomeOnly => _rangeExpenses.where((e) => e.isIncome).toList();

  Future<void> loadDateRangeExpenses(DateTime start, DateTime end) async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      final startOfDay = DateTime(start.year, start.month, start.day);
      _rangeExpenses = await DatabaseHelper.instance.getExpensesByDateRange(
        _userId!, startOfDay, endOfDay,
      );
      _rangeCategoryTotals = await DatabaseHelper.instance.getCategoryTotalsByDateRange(
        _userId!, startOfDay, endOfDay, type: 'expense',
      );
      _rangeIncomeCategoryTotals = await DatabaseHelper.instance.getCategoryTotalsByDateRange(
        _userId!, startOfDay, endOfDay, type: 'income',
      );
      _rangeExpenseTotal = await DatabaseHelper.instance.getTotalByDateRange(
        _userId!, startOfDay, endOfDay, type: 'expense',
      );
      _rangeIncomeTotal = await DatabaseHelper.instance.getTotalByDateRange(
        _userId!, startOfDay, endOfDay, type: 'income',
      );
    } catch (e) {
      debugPrint('Error loading date range expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      await DatabaseHelper.instance.createExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    try {
      await DatabaseHelper.instance.updateExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error updating expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await DatabaseHelper.instance.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }

  // ─── Recurring Expenses ───

  Future<bool> addRecurringExpense(RecurringExpenseModel recurring) async {
    try {
      await DatabaseHelper.instance.createRecurringExpense(recurring);
      _recurringExpenses = await DatabaseHelper.instance.getRecurringExpenses(_userId!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding recurring: $e');
      return false;
    }
  }

  Future<bool> deleteRecurringExpense(int id) async {
    try {
      await DatabaseHelper.instance.deleteRecurringExpense(id);
      _recurringExpenses.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting recurring: $e');
      return false;
    }
  }

  Future<bool> toggleRecurring(RecurringExpenseModel recurring) async {
    try {
      final updated = recurring.copyWith(isActive: !recurring.isActive);
      await DatabaseHelper.instance.updateRecurringExpense(updated);
      final idx = _recurringExpenses.indexWhere((r) => r.id == recurring.id);
      if (idx >= 0) _recurringExpenses[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Analytics helpers ───

  List<double> get sparklineData {
    final now = DateTime.now();
    final data = <double>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final match = _dailyTotals.where((d) => (d['day'] as String?) == dayStr);
      if (match.isNotEmpty) {
        data.add((match.first['total'] as num?)?.toDouble() ?? 0);
      } else {
        data.add(0);
      }
    }
    return data;
  }

  // Simple linear regression for trend
  Map<String, dynamic> get spendingTrend {
    final data = sparklineData;
    if (data.every((d) => d == 0)) return {'slope': 0.0, 'direction': 'flat'};

    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    String direction;
    if (slope > 5) {
      direction = 'increasing';
    } else if (slope < -5) {
      direction = 'decreasing';
    } else {
      direction = 'stable';
    }
    return {'slope': slope, 'direction': direction};
  }

  void clear() {
    _expenses = [];
    _todayExpenses = [];
    _monthlyExpenses = [];
    _last7DaysExpenses = [];
    _recurringExpenses = [];
    _categoryTotals = {};
    _incomeCategoryTotals = {};
    _dailyTotals = [];
    _monthlyTotal = 0;
    _monthlyIncomeTotal = 0;
    _previousMonthTotal = 0;
    _todayTotal = 0;
    _userId = null;
    notifyListeners();
  }
}
