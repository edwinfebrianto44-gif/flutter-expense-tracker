import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReportNotifier(apiService);
});

class ReportState {
  final bool isLoading;
  final String? errorMessage;
  final MonthlySummary? monthlySummary;
  final YearlySummary? yearlySummary;
  final TrendsData? trends;
  final InsightsData? insights;
  final CategoryAnalysis? categoryAnalysis;
  final DashboardData? dashboardData;

  const ReportState({
    this.isLoading = false,
    this.errorMessage,
    this.monthlySummary,
    this.yearlySummary,
    this.trends,
    this.insights,
    this.categoryAnalysis,
    this.dashboardData,
  });

  ReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    MonthlySummary? monthlySummary,
    YearlySummary? yearlySummary,
    TrendsData? trends,
    InsightsData? insights,
    CategoryAnalysis? categoryAnalysis,
    DashboardData? dashboardData,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      yearlySummary: yearlySummary ?? this.yearlySummary,
      trends: trends ?? this.trends,
      insights: insights ?? this.insights,
      categoryAnalysis: categoryAnalysis ?? this.categoryAnalysis,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ApiService _apiService;

  ReportNotifier(this._apiService) : super(const ReportState());

  Future<void> loadMonthlySummary(String month) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        '/reports/summary',
        queryParameters: {
          'month': month,
          'include_breakdown': true,
        },
      );

      if (response.data['data'] != null) {
        final summary = MonthlySummary.fromJson(response.data['data']);
        state = state.copyWith(
          isLoading: false,
          monthlySummary: summary,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No data received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadYearlySummary(int year) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get('/reports/yearly/$year');

      if (response.data['data'] != null) {
        final summary = YearlySummary.fromJson(response.data['data']);
        state = state.copyWith(
          isLoading: false,
          yearlySummary: summary,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No data received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadTrends(int months) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        '/reports/trends',
        queryParameters: {'months': months},
      );

      if (response.data['data'] != null) {
        final trends = TrendsData.fromJson(response.data['data']);
        state = state.copyWith(
          isLoading: false,
          trends: trends,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No data received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadInsights(int months) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        '/reports/insights',
        queryParameters: {'months': months},
      );

      if (response.data['data'] != null) {
        final insights = InsightsData.fromJson(response.data['data']);
        state = state.copyWith(
          isLoading: false,
          insights: insights,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No data received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadCategoryAnalysis(
    String startDate,
    String endDate, {
    String? categoryType,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final queryParams = {
        'start_date': startDate,
        'end_date': endDate,
      };

      if (categoryType != null) {
        queryParams['category_type'] = categoryType;
      }

      final response = await _apiService.get(
        '/reports/category-analysis',
        queryParameters: queryParams,
      );

      if (response.data['data'] != null) {
        final analysis = CategoryAnalysis.fromJson(response.data['data']);
        state = state.copyWith(
          isLoading: false,
          categoryAnalysis: analysis,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No data received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get('/reports/dashboard');

      if (response.data['data'] != null) {
        final dashboard = DashboardData.fromJson(response.data['data']);
        state = state.copyWith(
          isLoading: false,
          dashboardData: dashboard,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No data received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> exportReport(String type, String format, String period) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      String endpoint;
      if (type == 'monthly') {
        endpoint = '/reports/export/monthly/$format';
      } else {
        endpoint = '/reports/export/yearly/$period/$format';
      }

      final queryParams = type == 'monthly' ? {'month': period} : <String, dynamic>{};

      final response = await _apiService.dio.get(
        '${Constants.baseUrl}$endpoint',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer ${_apiService.accessToken}',
          },
        ),
      );

      // Handle file download here
      // You can save to device storage or share the file
      // For now, we'll just show a success message
      state = state.copyWith(isLoading: false);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const ReportState();
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          if (error.response?.data != null) {
            try {
              final data = error.response!.data;
              if (data is Map && data['message'] != null) {
                return data['message'];
              } else if (data is Map && data['detail'] != null) {
                if (data['detail'] is Map && data['detail']['message'] != null) {
                  return data['detail']['message'];
                }
                return data['detail'].toString();
              }
            } catch (_) {
              // Fallback to status code message
            }
          }
          return 'Server error: ${error.response?.statusCode}';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Connection error. Please check your internet connection.';
        case DioExceptionType.badCertificate:
          return 'Certificate error.';
        case DioExceptionType.unknown:
        default:
          return 'An unexpected error occurred.';
      }
    }
    return error.toString();
  }
}
