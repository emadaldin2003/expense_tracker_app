// database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'expense_tracker.db');
    return openDatabase(
      path,
      version: 4,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // v3: كلمات المرور أصبحت مُجزَّأة — نعيد البناء.
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('DROP TABLE IF EXISTS users');
      await _onCreate(db, newVersion);
    } else if (oldVersion < 4) {
      // v4: إضافة عمود الحذف الناعم دون فقد بيانات.
      await db.execute('ALTER TABLE expenses ADD COLUMN deleted_at TEXT');
    }
  }

  // ============ المستخدمون ============

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // ============ المعاملات ============

  Future<int> insertExpense(Expense expense, int userId) async {
    final db = await database;
    final map = expense.toMap();
    map['user_id'] = userId;
    return db.insert('expenses', map);
  }

  /// يقرأ المعاملات النشطة. يدعم بحثًا نصيًا ونطاقًا زمنيًا.
  /// [query] يطابق title أو category (LIKE مع parameterized whereArgs).
  /// [from]/[to] تُقارنان على level اليوم.
  Future<List<Expense>> getExpenses(
    int userId, {
    String? query,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final where = StringBuffer('user_id = ? AND deleted_at IS NULL');
    final whereArgs = <Object>[userId];

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      where.write(' AND (title LIKE ? OR category LIKE ?)');
      whereArgs.add(q);
      whereArgs.add(q);
    }
    if (from != null) {
      where.write(' AND date >= ?');
      whereArgs.add(
        DateTime(from.year, from.month, from.day).toIso8601String(),
      );
    }
    if (to != null) {
      where.write(' AND date <= ?');
      whereArgs.add(
        DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String(),
      );
    }

    final maps = await db.query(
      'expenses',
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map(Expense.fromMap).toList();
  }

  /// حذف ناعم: يضع `deleted_at`. المعاملة تصبح في السلة.
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.update(
      'expenses',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  /// استعادة من السلة.
  Future<int> restoreExpense(int id) async {
    final db = await database;
    return db.update(
      'expenses',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// حذف نهائي: لا رجعة.
  Future<int> permanentlyDeleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// المعاملات في السلة، مرتّبة بأحدث حذف.
  Future<List<Expense>> getTrashedExpenses(int userId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'user_id = ? AND deleted_at IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'deleted_at DESC',
    );
    return maps.map(Expense.fromMap).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    final map = expense.toMap()..remove('deleted_at');
    return db.update(
      'expenses',
      map,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [expense.id],
    );
  }

  Future<List<Expense>> getExpensesByCategory(
      String category, int userId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'category = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [category, userId],
      orderBy: 'date DESC',
    );
    return maps.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesByType(String type, int userId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'type = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [type, userId],
      orderBy: 'date DESC',
    );
    return maps.map(Expense.fromMap).toList();
  }

  Future<Map<String, dynamic>> getStatistics(
    int userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final where = StringBuffer('deleted_at IS NULL AND user_id = ?');
    final whereArgs = <Object>[userId];

    if (from != null) {
      where.write(' AND date >= ?');
      whereArgs.add(
        DateTime(from.year, from.month, from.day).toIso8601String(),
      );
    }
    if (to != null) {
      where.write(' AND date <= ?');
      whereArgs.add(
        DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String(),
      );
    }
    final clause = where.toString();

    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE type = "expense" AND $clause',
      whereArgs,
    );
    final totalExpenses =
        (expenseResult.first['total'] as num? ?? 0).toDouble();

    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE type = "income" AND $clause',
      whereArgs,
    );
    final totalIncome =
        (incomeResult.first['total'] as num? ?? 0).toDouble();

    final categoryResult = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses WHERE type = "expense" AND $clause GROUP BY category',
      whereArgs,
    );

    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'categoryExpenses': categoryResult,
    };
  }

  Future<double> getTotalByCategory(String category, int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE category = ? AND type = "expense" AND user_id = ? AND deleted_at IS NULL',
      [category, userId],
    );
    return (result.first['total'] as num? ?? 0).toDouble();
  }

  Future<int> getExpensesCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }
}