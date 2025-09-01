import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/custom_card.dart';
import '../../../utils/formatters.dart';

class ChartCard extends ConsumerStatefulWidget {
  const ChartCard({super.key});

  @override
  ConsumerState<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends ConsumerState<ChartCard>
    with TickerProviderStateMixin {
  bool _showIncome = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final monthlyData = ref.read(transactionProvider.notifier).getMonthlyData();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grafik Keuangan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ToggleButtons(
                isSelected: [_showIncome, !_showIncome],
                onPressed: (index) {
                  setState(() {
                    _showIncome = index == 0;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(
                  minHeight: 32,
                  minWidth: 60,
                ),
                children: const [
                  Text('Masuk'),
                  Text('Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildChart(context, monthlyData),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildLegend(context, monthlyData),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<String, double> data) {
    final thisMonthValue = _showIncome ? data['thisMonthIncome']! : data['thisMonthExpense']!;
    final lastMonthValue = _showIncome ? data['lastMonthIncome']! : data['lastMonthExpense']!;
    
    final maxValue = [thisMonthValue, lastMonthValue].reduce((a, b) => a > b ? a : b);
    final interval = maxValue > 0 ? maxValue / 4 : 1000000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                CurrencyFormatter.formatCompact(rod.toY),
                TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  CurrencyFormatter.formatCompact(value),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = ['Bulan Lalu', 'Bulan Ini'];
                return Text(
                  labels[value.toInt()],
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: lastMonthValue,
                color: _showIncome 
                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.7)
                    : Theme.of(context).colorScheme.error.withOpacity(0.7),
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: thisMonthValue,
                color: _showIncome 
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Map<String, double> data) {
    final thisMonthValue = _showIncome ? data['thisMonthIncome']! : data['thisMonthExpense']!;
    final lastMonthValue = _showIncome ? data['lastMonthIncome']! : data['lastMonthExpense']!;
    
    final percentage = lastMonthValue > 0 
        ? ((thisMonthValue - lastMonthValue) / lastMonthValue * 100)
        : 0.0;
    
    final isIncrease = percentage > 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showIncome ? 'Total Pemasukan' : 'Total Pengeluaran',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              CurrencyFormatter.format(thisMonthValue),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isIncrease ? 
              (_showIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error) :
              (_showIncome ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary)
            ).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncrease ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isIncrease ? 
                  (_showIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error) :
                  (_showIncome ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(width: 4),
              Text(
                '${percentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isIncrease ? 
                    (_showIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error) :
                    (_showIncome ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
