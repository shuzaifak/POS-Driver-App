import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/driver.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Driver? _driver;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  Driver? get driver => _driver;
  bool get isLoggedIn => _driver != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize and restore login state from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverJson = prefs.getString('driver_data');

      if (driverJson != null) {
        final driverMap = json.decode(driverJson);
        _driver = Driver.fromJson(driverMap);
        print('🔄 Restored driver from storage: ${_driver?.username}');
      }
    } catch (e) {
      print('❌ Error restoring auth state: $e');
      // Clear corrupted data
      await _clearStoredAuth();
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _driver = await ApiService.login(username, password);

      // Save to persistent storage
      await _saveAuthState();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _driver = null;

    // Clear from persistent storage
    await _clearStoredAuth();

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Save authentication state to storage
  Future<void> _saveAuthState() async {
    if (_driver == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverJson = json.encode(_driver!.toJson());
      await prefs.setString('driver_data', driverJson);
      print('💾 Saved driver data to storage');
    } catch (e) {
      print('❌ Error saving auth state: $e');
    }
  }

  // Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('driver_data');
      print('🗑️ Cleared stored auth data');
    } catch (e) {
      print('❌ Error clearing auth state: $e');
    }
  }

  // Optional: Check if stored token is still valid
  Future<bool> validateStoredAuth() async {
    if (_driver == null) return false;

    try {
      // You can add an API call here to validate the token
      // For now, we'll assume it's valid
      return true;
    } catch (e) {
      print('❌ Stored auth validation failed: $e');
      await logout();
      return false;
    }
  }
}