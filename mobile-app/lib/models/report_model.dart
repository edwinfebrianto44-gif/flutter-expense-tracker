import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

@freezed
class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required PeriodInfo period,
    required TotalsSummary totals,
    required TransactionCount transactionCount,
    CategoryBreakdown? categoryBreakdown,
    @Default([]) List<DailyBreakdown> dailyBreakdown,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}

@freezed
class YearlySummary with _$YearlySummary {
  const factory YearlySummary({
    required int year,
    required YearlyTotals totals,
    @Default([]) List<MonthlyData> monthlyBreakdown,
    YearlyInsights? insights,
  }) = _YearlySummary;

  factory YearlySummary.fromJson(Map<String, dynamic> json) =>
      _$YearlySummaryFromJson(json);
}

@freezed
class TrendsData with _$TrendsData {
  const factory TrendsData({
    required int periodMonths,
    required String startDate,
    required String endDate,
    @Default([]) List<TrendDataPoint> trends,
  }) = _TrendsData;

  factory TrendsData.fromJson(Map<String, dynamic> json) =>
      _$TrendsDataFromJson(json);
}

@freezed
class InsightsData with _$InsightsData {
  const factory InsightsData({
    required int periodMonths,
    required String startDate,
    required String endDate,
    @Default([]) List<Insight> insights,
    @Default([]) List<String> recommendations,
  }) = _InsightsData;

  factory InsightsData.fromJson(Map<String, dynamic> json) =>
      _$InsightsDataFromJson(json);
}

@freezed
class PeriodInfo with _$PeriodInfo {
  const factory PeriodInfo({
    required int year,
    required int month,
    required String monthName,
    required String startDate,
    required String endDate,
    required int daysInMonth,
  }) = _PeriodInfo;

  factory PeriodInfo.fromJson(Map<String, dynamic> json) =>
      _$PeriodInfoFromJson(json);
}

@freezed
class TotalsSummary with _$TotalsSummary {
  const factory TotalsSummary({
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required double savingsRate,
  }) = _TotalsSummary;

  factory TotalsSummary.fromJson(Map<String, dynamic> json) =>
      _$TotalsSummaryFromJson(json);
}

@freezed
class YearlyTotals with _$YearlyTotals {
  const factory YearlyTotals({
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required double averageMonthlyIncome,
    required double averageMonthlyExpense,
  }) = _YearlyTotals;

  factory YearlyTotals.fromJson(Map<String, dynamic> json) =>
      _$YearlyTotalsFromJson(json);
}

@freezed
class TransactionCount with _$TransactionCount {
  const factory TransactionCount({
    required int totalTransactions,
    required int incomeTransactions,
    required int expenseTransactions,
  }) = _TransactionCount;

  factory TransactionCount.fromJson(Map<String, dynamic> json) =>
      _$TransactionCountFromJson(json);
}

@freezed
class CategoryBreakdown with _$CategoryBreakdown {
  const factory CategoryBreakdown({
    @Default([]) List<CategoryData> income,
    @Default([]) List<CategoryData> expense,
  }) = _CategoryBreakdown;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownFromJson(json);
}

@freezed
class CategoryData with _$CategoryData {
  const factory CategoryData({
    required int id,
    required String name,
    required String type,
    required String icon,
    required String color,
    required double amount,
    required double percentage,
  }) = _CategoryData;

  factory CategoryData.fromJson(Map<String, dynamic> json) =>
      _$CategoryDataFromJson(json);
}

@freezed
class DailyBreakdown with _$DailyBreakdown {
  const factory DailyBreakdown({
    required String date,
    required int day,
    required double income,
    required double expense,
    required double balance,
  }) = _DailyBreakdown;

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) =>
      _$DailyBreakdownFromJson(json);
}

@freezed
class MonthlyData with _$MonthlyData {
  const factory MonthlyData({
    required int month,
    required String monthName,
    required double income,
    required double expense,
    required double balance,
  }) = _MonthlyData;

  factory MonthlyData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyDataFromJson(json);
}

@freezed
class TrendDataPoint with _$TrendDataPoint {
  const factory TrendDataPoint({
    required String period,
    required int year,
    required int month,
    required String monthName,
    required double income,
    required double expense,
    required double balance,
    required int incomeTransactions,
    required int expenseTransactions,
    required int totalTransactions,
  }) = _TrendDataPoint;

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) =>
      _$TrendDataPointFromJson(json);
}

@freezed
class YearlyInsights with _$YearlyInsights {
  const factory YearlyInsights({
    required MonthInsight bestMonth,
    required MonthInsight worstMonth,
    required MonthInsight highestIncomeMonth,
    required MonthInsight highestExpenseMonth,
  }) = _YearlyInsights;

  factory YearlyInsights.fromJson(Map<String, dynamic> json) =>
      _$YearlyInsightsFromJson(json);
}

@freezed
class MonthInsight with _$MonthInsight {
  const factory MonthInsight({
    required String month,
    double? balance,
    double? income,
    double? expense,
  }) = _MonthInsight;

  factory MonthInsight.fromJson(Map<String, dynamic> json) =>
      _$MonthInsightFromJson(json);
}

@freezed
class Insight with _$Insight {
  const factory Insight({
    required String type,
    required String title,
    required String value,
    required String description,
  }) = _Insight;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      _$InsightFromJson(json);
}

@freezed
class CategoryAnalysis with _$CategoryAnalysis {
  const factory CategoryAnalysis({
    required PeriodInfo period,
    required CategoryAnalysisSummary summary,
    @Default([]) List<CategoryAnalysisData> incomeCategories,
    @Default([]) List<CategoryAnalysisData> expenseCategories,
  }) = _CategoryAnalysis;

  factory CategoryAnalysis.fromJson(Map<String, dynamic> json) =>
      _$CategoryAnalysisFromJson(json);
}

@freezed
class CategoryAnalysisSummary with _$CategoryAnalysisSummary {
  const factory CategoryAnalysisSummary({
    required double totalAmount,
    required int totalTransactions,
    required int categoriesCount,
    required double averagePerCategory,
  }) = _CategoryAnalysisSummary;

  factory CategoryAnalysisSummary.fromJson(Map<String, dynamic> json) =>
      _$CategoryAnalysisSummaryFromJson(json);
}

@freezed
class CategoryAnalysisData with _$CategoryAnalysisData {
  const factory CategoryAnalysisData({
    required int id,
    required String name,
    required String type,
    required String icon,
    required String color,
    required double totalAmount,
    required int transactionCount,
    required double averageAmount,
    required double maxAmount,
    required double minAmount,
    required double percentage,
  }) = _CategoryAnalysisData;

  factory CategoryAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$CategoryAnalysisDataFromJson(json);
}

@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    required MonthlySummary currentMonth,
    required MonthlyComparison previousMonthComparison,
    required TrendsData trends,
    required InsightsData insights,
    required String lastUpdated,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}

@freezed
class MonthlyComparison with _$MonthlyComparison {
  const factory MonthlyComparison({
    required double incomeChange,
    required double expenseChange,
    required double incomeChangePercentage,
    required double expenseChangePercentage,
  }) = _MonthlyComparison;

  factory MonthlyComparison.fromJson(Map<String, dynamic> json) =>
      _$MonthlyComparisonFromJson(json);
}
