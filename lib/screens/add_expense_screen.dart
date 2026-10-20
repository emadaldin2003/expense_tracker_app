// screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final int userId;
  final Expense? expense; // null = إنشاء جديد

  const AddExpenseScreen({
    super.key,
    required this.userId,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dbHelper = DatabaseHelper();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'طعام';
  String _selectedType = 'expense';
  bool _saving = false;

  final List<String> _categories = const [
    'طعام',
    'مواصلات',
    'ترفيه',
    'سكن',
    'صحة',
    'تعليم',
    'أخرى',
  ];

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _selectedDate = e.date;
      _selectedCategory = _categories.contains(e.category)
          ? e.category
          : 'أخرى';
      _selectedType = e.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    try {
      if (_isEdit) {
        await _dbHelper.updateExpense(
          widget.expense!.copyWith(
            title: title,
            amount: amount,
            date: _selectedDate,
            category: _selectedCategory,
            type: _selectedType,
          ),
        );
      } else {
        final expense = Expense(
          title: title,
          amount: amount,
          date: _selectedDate,
          category: _selectedCategory,
          type: _selectedType,
        );
        await _dbHelper.insertExpense(expense, widget.userId);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'تعذر تحديث المعاملة'
              : 'تعذر حفظ المعاملة'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate.toLocal().toString().split(' ')[0];
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل معاملة' : 'إضافة معاملة جديدة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                DropdownMenuItem(value: 'income', child: Text('إيراد')),
              ],
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: 'نوع المعاملة'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'الوصف'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'يرجى إدخال وصف للمعاملة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixText: 'د.ك ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return 'يرجى إدخال مبلغ صحيح أكبر من صفر';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dateStr),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveExpense,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEdit ? Icons.save : Icons.check),
                label: Text(_isEdit ? 'تحديث المعاملة' : 'حفظ المعاملة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}