// screens/trash_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';

class TrashScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onDataChanged;
  const TrashScreen({
    super.key,
    required this.userId,
    required this.onDataChanged,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final _db = DatabaseHelper();
  List<Expense> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _db.getTrashedExpenses(widget.userId);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _restore(Expense e) async {
    try {
      await _db.restoreExpense(e.id!);
      await _load();
      widget.onDataChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الاستعادة')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذرت الاستعادة')),
      );
    }
  }

  Future<void> _deleteForever(Expense e) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف نهائي',
      message:
          'لا يمكن التراجع. هل تريد حذف "${e.title}" نهائيًا؟',
      confirmLabel: 'حذف نهائي',
      destructive: true,
    );
    if (ok != true) return;
    try {
      await _db.permanentlyDeleteExpense(e.id!);
      await _load();
      widget.onDataChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف النهائي')),
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
      appBar: AppBar(title: const Text('سلة المهملات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.delete_outline,
                  title: 'السلة فارغة',
                  subtitle: 'المعاملات المحذوفة ستظهر هنا',
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final e = _items[i];
                    return Card(
                      elevation: 0,
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: Icon(
                          e.type == 'expense'
                              ? Icons.trending_down
                              : Icons.trending_up,
                          color: e.type == 'expense'
                              ? scheme.error
                              : Colors.green.shade600,
                        ),
                        title: Text(e.title),
                        subtitle: Text(
                          '${e.category} • ${e.amount.toStringAsFixed(2)} ر.ي',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'استعادة',
                              icon: const Icon(Icons.restore),
                              onPressed: () => _restore(e),
                            ),
                            IconButton(
                              tooltip: 'حذف نهائي',
                              icon: Icon(Icons.delete_forever,
                                  color: scheme.error),
                              onPressed: () => _deleteForever(e),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}