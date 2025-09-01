import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000'; // Backend URL
  late Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await logout();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      
      // Save token and user data
      await StorageService.saveToken(data['access_token']);
      await StorageService.saveUserData(jsonEncode(data['user']));
      
      return {
        'success': true,
        'user': User.fromJson(data['user']),
        'token': data['access_token'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final data = response.data;
      
      // Save token and user data
      await StorageService.saveToken(data['access_token']);
      await StorageService.saveUserData(jsonEncode(data['user']));
      
      return {
        'success': true,
        'user': User.fromJson(data['user']),
        'token': data['access_token'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }

  Future<User?> getCurrentUser() async {
    try {
      final userData = await StorageService.getUserData();
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data['message'] != null) {
        return error.response!.data['message'];
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
