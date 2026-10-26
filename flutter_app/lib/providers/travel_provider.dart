import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class TravelProvider extends ChangeNotifier {
  late ApiService _apiService;

  List<Map<String, dynamic>> _travels = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedTravel;
  Map<String, dynamic>? _stats;

  // Getters
  List<Map<String, dynamic>> get travels => _travels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get selectedTravel => _selectedTravel;
  Map<String, dynamic>? get stats => _stats;

  TravelProvider() {
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
  }

  // Get travels
  Future<void> getTravels({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _travels = await _apiService.getTravels(status: status);
      await getStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get single travel
  Future<void> getTravel(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedTravel = await _apiService.getTravel(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create travel
  Future<bool> createTravel(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.createTravel(data);
      _travels.add(result);
      await getStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update travel
  Future<bool> updateTravel(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateTravel(id, data);
      final index = _travels.indexWhere((t) => t['travel_id'] == id);
      if (index != -1) {
        _travels[index] = result;
      }
      _selectedTravel = result;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete travel
  Future<bool> deleteTravel(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteTravel(id);
      _travels.removeWhere((t) => t['travel_id'] == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get stats
  Future<void> getStats() async {
    try {
      _stats = await _apiService.getTravelStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
