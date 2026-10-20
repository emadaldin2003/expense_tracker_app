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
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return await openDatabase(
      path,
      version: 3,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // تفعيل فرض المفاتيح الأجنبية على كل اتصال.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // إنشاء جدول المستخدمين
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // إنشاء جدول المصروفات مع ربطه بالمستخدم
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // v3: كلمات المرور أصبحت مُجزَّأة. البيانات القديمة (نص صريح)
      // لا يمكن ترحيلها بأمان، لذا نعيد إنشاء الجدولين من الصفر.
      // ترتيب الحذف مهم بسبب المفتاح الأجنبي: expenses ثم users.
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('DROP TABLE IF EXISTS users');
      await _onCreate(db, newVersion);
    }
  }

  // دوال إدارة المستخدمين
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // دوال المصروفات
  Future<int> insertExpense(Expense expense, int userId) async {
    Database db = await database;
    Map<String, dynamic> expenseMap = expense.toMap();
    expenseMap['user_id'] = userId;
    return await db.insert('expenses', expenseMap);
  }

  Future<List<Expense>> getExpenses(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateExpense(Expense expense) async {
    Database db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<List<Expense>> getExpensesByCategory(
      String category, int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'category = ? AND user_id = ?',
      whereArgs: [category, userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getExpensesByType(String type, int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'type = ? AND user_id = ?',
      whereArgs: [type, userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<Map<String, dynamic>> getStatistics(int userId) async {
    Database db = await database;

    // إجمالي المصروفات
    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE type = "expense" AND user_id = ?',
      [userId],
    );
    final totalExpenses = expenseResult.first['total'] as num? ?? 0;

    // إجمالي الإيرادات
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE type = "income" AND user_id = ?',
      [userId],
    );
    final totalIncome = incomeResult.first['total'] as num? ?? 0;

    // المصروفات حسب الفئة
    final categoryResult = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses WHERE type = "expense" AND user_id = ? GROUP BY category',
      [userId],
    );

    return {
      'totalExpenses': totalExpenses.toDouble(),
      'totalIncome': totalIncome.toDouble(),
      'categoryExpenses': categoryResult,
    };
  }

  Future<double> getTotalByCategory(String category, int userId) async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE category = ? AND type = "expense" AND user_id = ?',
      [category, userId],
    );
    return (result.first['total'] as num? ?? 0).toDouble();
  }

  Future<int> getExpensesCount(int userId) async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }
}