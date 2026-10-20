// widgets/expense_card.dart
import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Function onDelete;

  const ExpenseCard({
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: expense.type == 'expense' 
                ? Colors.red.withOpacity(0.1) 
                : Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            expense.type == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
            color: expense.type == 'expense' ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          expense.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${expense.category} - ${expense.date.toLocal().toString().split(' ')[0]}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${expense.amount.toStringAsFixed(2)} د.ك',
          style: TextStyle(
            color: expense.type == 'expense' ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('حذف المعاملة'),
              content: Text('هل تريد حذف هذه المعاملة؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    onDelete();
                    Navigator.pop(context);
                  },
                  child: Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}