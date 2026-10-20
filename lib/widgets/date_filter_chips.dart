// widgets/date_filter_chips.dart
import 'package:flutter/material.dart';

enum DateFilter { all, today, week, month }

extension DateFilterLabel on DateFilter {
  String get label {
    switch (this) {
      case DateFilter.all:
        return 'الكل';
      case DateFilter.today:
        return 'اليوم';
      case DateFilter.week:
        return 'هذا الأسبوع';
      case DateFilter.month:
        return 'هذا الشهر';
    }
  }
}

/// نطاق التاريخ المقابل للمرشّح. يعيد null للمرشّح "الكل".
DateTimeRange? rangeFromFilter(DateFilter f) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  switch (f) {
    case DateFilter.all:
      return null;
    case DateFilter.today:
      return DateTimeRange(start: today, end: today);
    case DateFilter.week:
      // الأسبوع يبدأ السبت (Dart: Sat=6, Sun=7, Mon=1..Fri=5)
      final days = (now.weekday + 1) % 7;
      return DateTimeRange(
        start: today.subtract(Duration(days: days)),
        end: today,
      );
    case DateFilter.month:
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: today,
      );
  }
}

class DateFilterChips extends StatelessWidget {
  final DateFilter selected;
  final ValueChanged<DateFilter> onChanged;

  const DateFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: DateFilter.values.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(f.label),
              selected: f == selected,
              onSelected: (_) => onChanged(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}