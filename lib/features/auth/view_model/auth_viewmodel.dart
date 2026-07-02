import 'package:flutter/material.dart';
import '../model/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Mock API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (email.isNotEmpty && password.isNotEmpty) {
        _currentUser = UserModel(
          id: '123',
          name: 'Test Driver',
          email: email,
        );
      } else {
        _errorMessage = "Invalid credentials";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }
}
