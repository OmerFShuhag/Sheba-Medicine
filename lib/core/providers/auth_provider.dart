import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      await logout();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _setLoading(true);
      final userData = await _apiService.getProfile();
      _user = User.fromJson(userData);
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      await logout();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.login(username, password);

      
      Map<String, dynamic>? userData;

      if (response['user'] != null) {
        userData = response['user'];
      } else if (response['id'] != null) {
        
        userData = response;
      }

      if (userData != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Login successful but no user data received';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.register(userData);
      Map<String, dynamic>? userResponseData;

      if (response['user'] != null) {
        userResponseData = response['user'];
      } else if (response['id'] != null) {
        userResponseData = response;
      }

      if (userResponseData != null) {
        _user = User.fromJson(userResponseData);
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Registration successful but no user data received';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _apiService.clearAuthTokens();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      final hasToken = await _apiService.hasValidToken();
      if (hasToken) {
        final userData = await _apiService.getProfile();
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _error = null;
      } else {
        _user = null;
        _isAuthenticated = false;
      }
      notifyListeners();
    } catch (e) {
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

 
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
