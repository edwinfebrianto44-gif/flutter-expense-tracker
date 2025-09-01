import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/date_utils.dart';
import '../generated/l10n.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    ref.read(reportProvider.notifier).loadMonthlySummary(monthStr);
    ref.read(reportProvider.notifier).loadYearlySummary(_selectedYear);
    ref.read(reportProvider.notifier).loadTrends(6);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportState = ref.watch(reportProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsAnalytics),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.calendar_month), text: l10n.monthly),
            Tab(icon: const Icon(Icons.calendar_today), text: l10n.yearly),
            Tab(icon: const Icon(Icons.trending_up), text: l10n.trends),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyTab(reportState, theme),
          _buildYearlyTab(reportState, theme),
          _buildTrendsTab(reportState, theme),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab(ReportState reportState, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
        await ref.read(reportProvider.notifier).loadMonthlySummary(monthStr);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 20),
            
            if (reportState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reportState.monthlySummary != null) ...[
              _buildMonthlySummaryCards(reportState.monthlySummary!, theme),
              const SizedBox(height: 20),
              _buildCategoryPieChart(reportState.monthlySummary!, theme),
              const SizedBox(height: 20),
              _buildDailyChart(reportState.monthlySummary!, theme),
              const SizedBox(height: 20),
              _buildExportButtons('monthly'),
            ] else if (reportState.errorMessage != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(reportState.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
                        ref.read(reportProvider.notifier).loadMonthlySummary(monthStr);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyTab(ReportState reportState, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reportProvider.notifier).loadYearlySummary(_selectedYear);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearSelector(),
            const SizedBox(height: 20),
            
            if (reportState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reportState.yearlySummary != null) ...[
              _buildYearlySummaryCards(reportState.yearlySummary!, theme),
              const SizedBox(height: 20),
              _buildMonthlyBarChart(reportState.yearlySummary!, theme),
              const SizedBox(height: 20),
              _buildYearlyInsights(reportState.yearlySummary!, theme),
              const SizedBox(height: 20),
              _buildExportButtons('yearly'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab(ReportState reportState, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reportProvider.notifier).loadTrends(6);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrendsSelector(),
            const SizedBox(height: 20),
            
            if (reportState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reportState.trends != null) ...[
              _buildTrendsChart(reportState.trends!, theme),
              const SizedBox(height: 20),
              if (reportState.insights != null)
                _buildInsightsCard(reportState.insights!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedYear.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => _changeYear(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () => _changeYear(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.trending_up),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Last 6 Months Trends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownButton<int>(
              value: 6,
              items: [3, 6, 12].map((months) {
                return DropdownMenuItem(
                  value: months,
                  child: Text('$months months'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(reportProvider.notifier).loadTrends(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCards(MonthlySummary summary, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            summary.totals.totalIncome,
            Icons.trending_up,
            Colors.green,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expense',
            summary.totals.totalExpense,
            Icons.trending_down,
            Colors.red,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Balance',
            summary.totals.balance,
            Icons.account_balance_wallet,
            summary.totals.balance >= 0 ? Colors.green : Colors.red,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildYearlySummaryCards(YearlySummary summary, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Income',
                summary.totals.totalIncome,
                Icons.trending_up,
                Colors.green,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Expense',
                summary.totals.totalExpense,
                Icons.trending_down,
                Colors.red,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Net Balance',
                summary.totals.balance,
                Icons.account_balance_wallet,
                summary.totals.balance >= 0 ? Colors.green : Colors.red,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Avg Monthly',
                summary.totals.averageMonthlyIncome - summary.totals.averageMonthlyExpense,
                Icons.calculate,
                Colors.blue,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(symbol: '\$').format(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(MonthlySummary summary, ThemeData theme) {
    if (summary.categoryBreakdown?.expense.isEmpty ?? true) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No expense data for pie chart'),
          ),
        ),
      );
    }

    final expenseCategories = summary.categoryBreakdown!.expense;
    final total = expenseCategories.fold<double>(
      0, (sum, category) => sum + category.amount,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Categories',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: expenseCategories.take(8).map((category) {
                          final percentage = (category.amount / total) * 100;
                          return PieChartSectionData(
                            value: category.amount,
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: _parseColor(category.color) ?? Colors.blue,
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: expenseCategories.length,
                      itemBuilder: (context, index) {
                        final category = expenseCategories[index];
                        final percentage = (category.amount / total) * 100;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _parseColor(category.color) ?? Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart(MonthlySummary summary, ThemeData theme) {
    if (summary.dailyBreakdown.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No daily data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Income vs Expense',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt();
                          if (day > 0 && day <= summary.dailyBreakdown.length) {
                            return Text(
                              day.toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Income line
                    LineChartBarData(
                      spots: summary.dailyBreakdown
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble() + 1,
                                entry.value.income,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    // Expense line
                    LineChartBarData(
                      spots: summary.dailyBreakdown
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble() + 1,
                                entry.value.expense,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart(YearlySummary summary, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Breakdown',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: summary.monthlyBreakdown
                      .asMap()
                      .entries
                      .map((entry) {
                        final month = entry.value;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: month.income,
                              color: Colors.green,
                              width: 12,
                            ),
                            BarChartRodData(
                              toY: month.expense,
                              color: Colors.red,
                              width: 12,
                            ),
                          ],
                        );
                      })
                      .toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final monthIndex = value.toInt();
                          if (monthIndex >= 0 && monthIndex < 12) {
                            return Text(
                              DateFormat('MMM').format(DateTime(2024, monthIndex + 1)),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart(TrendsData trends, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trends',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < trends.trends.length) {
                            return Text(
                              trends.trends[index].monthName.substring(0, 3),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.trends
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.income,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                    ),
                    LineChartBarData(
                      spots: trends.trends
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.expense,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyInsights(YearlySummary summary, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              'Best Month (Balance)',
              '${summary.insights?.bestMonth.month} (${NumberFormat.currency(symbol: '\$').format(summary.insights?.bestMonth.balance)})',
              Icons.trending_up,
              Colors.green,
            ),
            _buildInsightItem(
              'Highest Income',
              '${summary.insights?.highestIncomeMonth.month} (${NumberFormat.currency(symbol: '\$').format(summary.insights?.highestIncomeMonth.income)})',
              Icons.attach_money,
              Colors.blue,
            ),
            _buildInsightItem(
              'Highest Expense',
              '${summary.insights?.highestExpenseMonth.month} (${NumberFormat.currency(symbol: '\$').format(summary.insights?.highestExpenseMonth.expense)})',
              Icons.trending_down,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(InsightsData insights, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...insights.insights.map((insight) => _buildInsightItem(
                  insight.title,
                  insight.description,
                  _getInsightIcon(insight.type),
                  _getInsightColor(insight.type),
                )),
            if (insights.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...insights.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons(String reportType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport(reportType, 'csv'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport(reportType, 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport(reportType, 'excel'),
                    icon: const Icon(Icons.description),
                    label: const Text('Excel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    ref.read(reportProvider.notifier).loadMonthlySummary(monthStr);
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
    });
    ref.read(reportProvider.notifier).loadYearlySummary(_selectedYear);
  }

  void _exportReport(String type, String format) {
    String period;
    if (type == 'monthly') {
      period = DateFormat('yyyy-MM').format(_selectedMonth);
    } else {
      period = _selectedYear.toString();
    }
    
    ref.read(reportProvider.notifier).exportReport(type, format, period);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting $format report...'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'savings_rate':
        return Icons.savings;
      case 'top_expense_category':
        return Icons.category;
      case 'average_daily_spending':
        return Icons.calendar_today;
      default:
        return Icons.info;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'savings_rate':
        return Colors.green;
      case 'top_expense_category':
        return Colors.orange;
      case 'average_daily_spending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
