import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  late ApiService _apiService;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  // Get user role (super_admin, faculty, etc.)
  String get userRole => _currentUser?['role'] ?? 'faculty';
  
  // Check if user is admin
  bool get isAdmin => userRole == 'super_admin';
  
  // Get user full name
  String get fullName => _currentUser?['full_name'] ?? 'User';
  
  // Get user email
  String get email => _currentUser?['email'] ?? '';

  AuthProvider(this.prefs) {
    _apiService = ApiService(prefs);
    _checkAuthStatus();
  }

  // Check if user is already logged in
  void _checkAuthStatus() {
    final token = prefs.getString('accessToken');
    _isAuthenticated = token != null;
    if (_isAuthenticated) {
      _loadUserData();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.login(email, password);
      _isAuthenticated = true;
      await _loadUserData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load current user data
  Future<void> _loadUserData() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _isAuthenticated = false;
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
