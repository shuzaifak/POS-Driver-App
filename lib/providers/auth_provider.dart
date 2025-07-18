import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Driver? _driver;
  bool _isLoading = false;
  String? _error;

  Driver? get driver => _driver;
  bool get isLoggedIn => _driver != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _driver = await ApiService.login(username, password);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _driver = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
