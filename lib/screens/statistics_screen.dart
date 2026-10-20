// screens/statistics_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../widgets/date_filter_chips.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;
  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _db = DatabaseHelper();
  bool _loading = true;
  String? _error;
  DateFilter _filter = DateFilter.month;

  double _totalExpenses = 0;
  double _totalIncome = 0;
  double _balance = 0;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final range = rangeFromFilter(_filter);
      final stats = await _db.getStatistics(
        widget.userId,
        from: range?.start,
        to: range?.end,
      );
      final cats =
          (stats['categoryExpenses'] as List).cast<Map<String, dynamic>>();
      cats.sort((a, b) =>
          (b['total'] as num).compareTo(a['total'] as num));
      if (!mounted) return;
      setState(() {
        _totalExpenses = (stats['totalExpenses'] as num).toDouble();
        _totalIncome = (stats['totalIncome'] as num).toDouble();
        _balance = _totalIncome - _totalExpenses;
        _categories = cats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الإحصائيات';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: Column(
        children: [
          DateFilterChips(
            selected: _filter,
            onChanged: (f) {
              setState(() => _filter = f);
              _load();
            },
          ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 64, color: scheme.error),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _load,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  Row(
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'المصروفات حسب الفئة',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyState(
                        icon: Icons.pie_chart_outline,
                        title: 'لا توجد بيانات لهذه الفترة',
                        subtitle: 'أضف معاملات لعرض التفصيل',
                      ),
                    )
                  else
                    ..._categories.map((c) => _CategoryRow(
                          name: c['category'] as String,
                          total: (c['total'] as num).toDouble(),
                          parentTotal: _totalExpenses,
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double total;
  final double parentTotal;
  const _CategoryRow({
    required this.name,
    required this.total,
    required this.parentTotal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = parentTotal > 0
        ? (total / parentTotal).clamp(0.0, 1.0)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${total.toStringAsFixed(2)} ر.ي (${(pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}