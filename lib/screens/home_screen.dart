// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../widgets/expense_list.dart';
import 'add_expense_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Expense> _expenses = [];
  double _totalExpenses = 0;
  double _totalIncome = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await _dbHelper.getExpenses(widget.userId);
      final statistics = await _dbHelper.getStatistics(widget.userId);

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _totalExpenses =
            (statistics['totalExpenses'] as num?)?.toDouble() ?? 0.0;
        _totalIncome =
            (statistics['totalIncome'] as num?)?.toDouble() ?? 0.0;
        _balance = _totalIncome - _totalExpenses;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل البيانات، اسحب للأسفل للمحاولة مجددًا'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تتبع المصروفات'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // الإحصائيات
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalCard('المصروفات', _totalExpenses, Colors.red),
                _buildTotalCard('الإيرادات', _totalIncome, Colors.green),
                _buildTotalCard('المتبقي', _balance,
                    _balance >= 0 ? Colors.blue : Colors.orange),
              ],
            ),
          ),

          // معلومات سريعة
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'المعاملات: ${_expenses.length}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'آخر تحديث: ${DateTime.now().toString().split(' ')[1].substring(0, 5)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ExpenseList(
              expenses: _expenses,
              onDelete: _deleteExpense,
              onRefresh: _loadExpenses,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(userId: widget.userId),
            ),
          );
          _loadExpenses();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildTotalCard(String title, double amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)} د.ك',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await _dbHelper.deleteExpense(id);
      await _loadExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف المعاملة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حذف المعاملة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}