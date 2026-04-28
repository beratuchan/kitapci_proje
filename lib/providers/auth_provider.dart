import 'package:flutter/foundation.dart';
import '../services/database_helper.dart'; // veya '../database_helper.dart'
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get userRole => _currentUser?.role ?? '';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userMap = await DatabaseHelper().getUserByEmail(email);
      if (userMap != null && userMap['password'] == password) {
        _currentUser = User.fromMap(userMap);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> register(User user) async {
    _isLoading = true;
    notifyListeners();
    try {
      final existing = await DatabaseHelper().getUserByEmail(user.email);
      if (existing != null) {
        return false;
      }
      final id = await DatabaseHelper().insertUser(user.toMap());
      _currentUser = User(
        id: id,
        email: user.email,
        password: user.password,
        role: user.role,
        name: user.name,
      );
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}