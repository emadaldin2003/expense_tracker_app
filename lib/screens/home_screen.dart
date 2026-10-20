// screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/date_filter_chips.dart';
import '../widgets/expense_list.dart';
import '../widgets/stat_card.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onDataChanged;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.onDataChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Expense> _expenses = [];
  double _totalExpenses = 0;
  double _totalIncome = 0;
  double _balance = 0;
  bool _loading = true;
  String? _error;
  DateFilter _filter = DateFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final range = rangeFromFilter(_filter);
      final list = await _db.getExpenses(
        widget.userId,
        query: _searchController.text,
        from: range?.start,
        to: range?.end,
      );
      final stats = await _db.getStatistics(
        widget.userId,
        from: range?.start,
        to: range?.end,
      );
      if (!mounted) return;
      setState(() {
        _expenses = list;
        _totalExpenses = (stats['totalExpenses'] as num).toDouble();
        _totalIncome = (stats['totalIncome'] as num).toDouble();
        _balance = _totalIncome - _totalExpenses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل البيانات';
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  void _onFilterChanged(DateFilter f) {
    setState(() => _filter = f);
    _load();
  }

  Future<void> _openAdd() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(userId: widget.userId),
      ),
    );
    if (ok == true) {
      await _load();
      widget.onDataChanged();
    }
  }

  Future<void> _openEdit(Expense e) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          userId: widget.userId,
          expense: e,
        ),
      ),
    );
    if (ok == true) {
      await _load();
      widget.onDataChanged();
    }
  }

  Future<void> _confirmDelete(Expense e) async {
    final ok = await showConfirmDialog(
      context,
      title: 'نقل إلى السلة',
      message: 'هل تريد نقل "${e.title}" إلى سلة المهملات؟',
      confirmLabel: 'نقل',
      destructive: true,
    );
    if (ok != true) return;
    try {
      await _db.deleteExpense(e.id!);
      await _load();
      widget.onDataChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم النقل إلى السلة')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحذف')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع المصروفات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'بحث بالوصف أو الفئة',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          DateFilterChips(
            selected: _filter,
            onChanged: _onFilterChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'الإيرادات',
                    amountText: _totalIncome.toStringAsFixed(2),
                    icon: Icons.trending_up,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'المصروفات',
                    amountText: _totalExpenses.toStringAsFixed(2),
                    icon: Icons.trending_down,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'المتبقي',
                    amountText: _balance.toStringAsFixed(2),
                    icon: Icons.account_balance_wallet_outlined,
                    color: _balance >= 0
                        ? scheme.primary
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ExpenseList(
              expenses: _expenses,
              loading: _loading,
              error: _error,
              onRefresh: _load,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('معاملة'),
      ),
    );
  }
}