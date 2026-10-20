// screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final int userId;

  AddExpenseScreen({required this.userId});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dbHelper = DatabaseHelper();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'طعام';
  String _selectedType = 'expense';

  final List<String> _categories = [
    'طعام',
    'مواصلات',
    'ترفيه',
    'سكن',
    'صحة',
    'تعليم',
    'أخرى'
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final expense = Expense(
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      category: _selectedCategory,
      type: _selectedType,
    );

    try {
      await _dbHelper.insertExpense(expense, widget.userId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ المعاملة، حاول مجددًا'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة معاملة جديدة'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // نوع المعاملة
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: [
                  DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                  DropdownMenuItem(value: 'income', child: Text('إيراد')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'نوع المعاملة',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              // العنوان
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال وصف للمعاملة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(),
                  prefixText: 'د.ك ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // الفئة
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              // التاريخ
              ListTile(
                title: Text(
                  'التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text('حفظ المعاملة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}