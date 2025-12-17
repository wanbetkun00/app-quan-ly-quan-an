import 'package:flutter/material.dart';
import '../models/enums.dart';

class AuthProvider extends ChangeNotifier {
  UserRole? _role;
  String? _username;
  String? _employeeId;

  UserRole? get role => _role;
  String? get username => _username;
  String? get employeeId => _employeeId;

  bool get isLoggedIn => _role != null;

  // Demo accounts (đơn giản, không mã hoá)
  // Nhân viên: username = staff, password = 1234 -> employeeId = 'staff'
  // Quản lý:  username = manager, password = 1234 -> employeeId = 'manager'
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 300)); // giả lập delay

    if (username == 'staff' && password == '1234') {
      _role = UserRole.staff;
      _username = username;
      _employeeId = 'staff'; // Map username to employeeId
      notifyListeners();
      return true;
    }

    if (username == 'manager' && password == '1234') {
      _role = UserRole.manager;
      _username = username;
      _employeeId = 'manager'; // Map username to employeeId
      notifyListeners();
      return true;
    }

    return false;
  }

  void logout() {
    _role = null;
    _username = null;
    _employeeId = null;
    notifyListeners();
  }
}


