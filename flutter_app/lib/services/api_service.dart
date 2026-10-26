import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  late Dio _dio;
  final SharedPreferences _prefs;

  ApiService(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _prefs.getString('accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          developer.log('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onError: (error, handler) {
          developer.log('Error: ${error.message}');
          return handler.next(error);
        },
        onResponse: (response, handler) {
          developer.log('Response: ${response.statusCode}');
          return handler.next(response);
        },
      ),
    );
  }

  // ==================== Authentication ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      await _prefs.setString('accessToken', data['access_token']);
      await _prefs.setString('refreshToken', data['refresh_token']);
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = _prefs.getString('refreshToken');
      if (refreshToken == null) throw Exception('No refresh token');

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      await _prefs.setString('accessToken', data['access_token']);
      await _prefs.setString('refreshToken', data['refresh_token']);
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await _prefs.remove('accessToken');
      await _prefs.remove('refreshToken');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Travels ====================

  Future<List<Map<String, dynamic>>> getTravels({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    try {
      String query = '?skip=$skip&limit=$limit';
      if (status != null) query += '&status=$status';

      final response = await _dio.get('/travels/$query');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTravel(int id) async {
    try {
      final response = await _dio.get('/travels/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTravel(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/travels/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTravel(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/travels/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTravel(int id) async {
    try {
      await _dio.delete('/travels/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTravelStats() async {
    try {
      final response = await _dio.get('/travels/statistics');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Documents ====================

  Future<List<Map<String, dynamic>>> getDocuments(int travelId) async {
    try {
      final response = await _dio.get('/documents/travel/$travelId');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required int travelId,
    required String docType,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'travel_id': travelId,
        'doc_type': docType,
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post('/documents/upload', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Analytics ====================

  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final response = await _dio.get('/analytics/user/summary');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTravelCompliance(int travelId) async {
    try {
      final response = await _dio.get('/analytics/travel/$travelId/compliance');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTravelRisk(int travelId) async {
    try {
      final response = await _dio.get('/analytics/travel/$travelId/risk');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Notifications ====================

  Future<List<Map<String, dynamic>>> getNotifications({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications/?skip=$skip&limit=$limit',
      );
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Announcements ====================

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _dio.get('/announcements/');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Admin Endpoints ====================

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final response = await _dio.get('/admin/dashboard/stats');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAdminTravels({
    int skip = 0,
    int limit = 50,
    String? status,
    String? college,
  }) async {
    try {
      String query = '?skip=$skip&limit=$limit';
      if (status != null) query += '&status=$status';
      if (college != null) query += '&college=$college';

      final response = await _dio.get('/admin/travels/$query');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAdminUsers({
    int skip = 0,
    int limit = 50,
    String? role,
  }) async {
    try {
      String query = '?skip=$skip&limit=$limit';
      if (role != null) query += '&role=$role';

      final response = await _dio.get('/admin/users/$query');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAdminReports() async {
    try {
      final response = await _dio.get('/admin/reports/summary');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get('/admin/activities?limit=$limit');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Error Handling ====================

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map) {
        return data['detail'] ?? 'An error occurred';
      }
    }
    return error.message ?? 'An error occurred';
  }
}
