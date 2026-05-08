import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/wallet_model.dart';
import '../models/recurring_expense_model.dart';
import '../models/savings_goal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add type column to expenses
      await db.execute(
        "ALTER TABLE expenses ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
      );
      // Add profile_photo_path column to users
      await db.execute("ALTER TABLE users ADD COLUMN profile_photo_path TEXT");
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        display_name TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        monthly_budget REAL NOT NULL DEFAULT 1000.0,
        avatar_emoji TEXT,
        profile_photo_path TEXT,
        pin INT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        note TEXT,
        date TEXT NOT NULL,
        wallet_id INTEGER,
        receipt_path TEXT,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        recurring_id INTEGER,
        split_group_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        icon TEXT DEFAULT '💰',
        color INTEGER DEFAULT 0xFF7C3AED,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        wallet_id INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT,
        last_triggered TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        emoji TEXT DEFAULT '🎯',
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0.0,
        deadline TEXT NOT NULL,
        color INTEGER DEFAULT 0xFF7C3AED,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_expenses_user ON expenses(user_id)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_type ON expenses(type)');
    await db.execute('CREATE INDEX idx_wallets_user ON wallets(user_id)');
    await db.execute(
      'CREATE INDEX idx_recurring_user ON recurring_expenses(user_id)',
    );
    await db.execute('CREATE INDEX idx_goals_user ON savings_goals(user_id)');
  }

  // ═══════════════════════════════════════════════
  // ─── User Operations ───
  // ═══════════════════════════════════════════════

  Future<int> createUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> authenticateUser(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Expense Operations ───
  // ═══════════════════════════════════════════════

  Future<int> createExpense(ExpenseModel expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<ExpenseModel>> getExpenses(
    int userId, {
    bool showHidden = false,
  }) async {
    final db = await database;
    final where = showHidden ? 'user_id = ?' : 'user_id = ? AND is_hidden = 0';
    final maps = await db.query(
      'expenses',
      where: where,
      whereArgs: [userId],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<List<ExpenseModel>> getExpensesByDateRange(
    int userId,
    DateTime start,
    DateTime end, {
    bool showHidden = false,
  }) async {
    final db = await database;
    final where = showHidden
        ? 'user_id = ? AND date >= ? AND date <= ?'
        : 'user_id = ? AND date >= ? AND date <= ? AND is_hidden = 0';
    final maps = await db.query(
      'expenses',
      where: where,
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<List<ExpenseModel>> getExpensesByMonth(
    int userId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getExpensesByDateRange(userId, start, end);
  }

  Future<List<ExpenseModel>> getTodayExpenses(int userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getExpensesByDateRange(userId, start, end);
  }

  Future<List<ExpenseModel>> getLast7DaysExpenses(int userId) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getExpensesByDateRange(userId, start, end);
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getMonthlyTotal(
    int userId,
    int year,
    int month, {
    String type = 'expense',
  }) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND date >= ? AND date <= ? AND is_hidden = 0 AND type = ?",
      [userId, start, end, type],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMonthlyIncome(int userId, int year, int month) async {
    return getMonthlyTotal(userId, year, month, type: 'income');
  }

  Future<double> getMonthlyExpense(int userId, int year, int month) async {
    return getMonthlyTotal(userId, year, month, type: 'expense');
  }

  Future<Map<String, double>> getCategoryTotals(
    int userId,
    int year,
    int month, {
    String? type,
  }) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    String query =
        'SELECT category, SUM(amount) as total FROM expenses WHERE user_id = ? AND date >= ? AND date <= ? AND is_hidden = 0';
    final args = <dynamic>[userId, start, end];
    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }
    query += ' GROUP BY category ORDER BY total DESC';
    final result = await db.rawQuery(query, args);
    final map = <String, double>{};
    for (final row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
    int userId,
    int days,
  ) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1)).toIso8601String();
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();
    final result = await db.rawQuery(
      "SELECT DATE(date) as day, SUM(amount) as total FROM expenses WHERE user_id = ? AND date >= ? AND date <= ? AND is_hidden = 0 AND type = 'expense' GROUP BY DATE(date) ORDER BY day ASC",
      [userId, start, end],
    );
    return result;
  }

  Future<Map<String, double>> getCategoryTotalsByDateRange(
    int userId,
    DateTime start,
    DateTime end, {
    String? type,
  }) async {
    final db = await database;
    String query =
        'SELECT category, SUM(amount) as total FROM expenses WHERE user_id = ? AND date >= ? AND date <= ? AND is_hidden = 0';
    final args = <dynamic>[
      userId,
      start.toIso8601String(),
      end.toIso8601String(),
    ];
    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }
    query += ' GROUP BY category ORDER BY total DESC';
    final result = await db.rawQuery(query, args);
    final map = <String, double>{};
    for (final row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<double> getTotalByDateRange(
    int userId,
    DateTime start,
    DateTime end, {
    String type = 'expense',
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND date >= ? AND date <= ? AND is_hidden = 0 AND type = ?",
      [userId, start.toIso8601String(), end.toIso8601String(), type],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ═══════════════════════════════════════════════
  // ─── Wallet Operations ───
  // ═══════════════════════════════════════════════

  Future<int> createWallet(WalletModel wallet) async {
    final db = await database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<WalletModel>> getWallets(int userId) async {
    final db = await database;
    final maps = await db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => WalletModel.fromMap(map)).toList();
  }

  Future<int> updateWallet(WalletModel wallet) async {
    final db = await database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<int> deleteWallet(int id) async {
    final db = await database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getWalletSpent(int walletId, int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE wallet_id = ? AND date >= ? AND date <= ?',
      [walletId, start, end],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ═══════════════════════════════════════════════
  // ─── Recurring Expense Operations ───
  // ═══════════════════════════════════════════════

  Future<int> createRecurringExpense(RecurringExpenseModel recurring) async {
    final db = await database;
    return await db.insert('recurring_expenses', recurring.toMap());
  }

  Future<List<RecurringExpenseModel>> getRecurringExpenses(int userId) async {
    final db = await database;
    final maps = await db.query(
      'recurring_expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => RecurringExpenseModel.fromMap(map)).toList();
  }

  Future<int> updateRecurringExpense(RecurringExpenseModel recurring) async {
    final db = await database;
    return await db.update(
      'recurring_expenses',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  Future<int> deleteRecurringExpense(int id) async {
    final db = await database;
    return await db.delete(
      'recurring_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Savings Goal Operations ───
  // ═══════════════════════════════════════════════

  Future<int> createSavingsGoal(SavingsGoalModel goal) async {
    final db = await database;
    return await db.insert('savings_goals', goal.toMap());
  }

  Future<List<SavingsGoalModel>> getSavingsGoals(int userId) async {
    final db = await database;
    final maps = await db.query(
      'savings_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return maps.map((map) => SavingsGoalModel.fromMap(map)).toList();
  }

  Future<int> updateSavingsGoal(SavingsGoalModel goal) async {
    final db = await database;
    return await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteSavingsGoal(int id) async {
    final db = await database;
    return await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  // ─── Export / Backup ───
  // ═══════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllExpensesRaw(int userId) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
