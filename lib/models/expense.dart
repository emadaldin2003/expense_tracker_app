// models/expense.dart
class Expense {
  int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String type; // 'expense' أو 'income'
  final DateTime? deletedAt; // null = نشط، غير null = في السلة

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? type,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'type': type,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final deletedAtStr = map['deleted_at'] as String?;
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      type: map['type'] as String,
      deletedAt:
          deletedAtStr != null ? DateTime.parse(deletedAtStr) : null,
    );
  }
}