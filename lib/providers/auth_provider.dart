import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  final UserService _userService = UserService();

  AuthProvider() {
    _initUser();
  }

  void _initUser() {
    _userService.getCurrentUser().listen(
      (user) {
        print('AuthProvider: Got user update');
        if (user != null) {
          print('AuthProvider: User profile - ');
          print('Name: ${user.name}');
          print('Department: ${user.department}');
          print('Year: ${user.year}');
          print('Section: ${user.section}');
          print('StudentId: ${user.studentId}');
        } else {
          print('AuthProvider: No user data');
        }
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        print('AuthProvider: Error getting user - $error');
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> login(String regNo) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get user data from UserService
      final user = await _userService.getUserByRegNo(regNo);
      if (user != null) {
        _currentUser = user;
      } else {
        _error = 'User not found';
      }
    } catch (e) {
      _error = 'Failed to login: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
