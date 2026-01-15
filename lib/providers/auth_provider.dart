import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../services/error_handler.dart';
import '../services/firestore_service.dart';
import '../services/password_service.dart';
import '../models/employee_model.dart';

class AuthProvider extends ChangeNotifier {
  UserRole? _role;
  String? _username;
  String? _employeeId;
  EmployeeModel? _currentEmployee;

  final FirestoreService _firestoreService = FirestoreService();
  final PasswordService _passwordService = PasswordService();
  final ErrorHandler _errorHandler = ErrorHandler();

  UserRole? get role => _role;
  String? get username => _username;
  String? get employeeId => _employeeId;
  EmployeeModel? get currentEmployee => _currentEmployee;

  bool get isLoggedIn => _role != null;

  // Đăng nhập từ Firestore employees collection
  // Fallback: Các tài khoản demo (staff/1234, manager/1234) vẫn hoạt động
  Future<bool> login(String username, String password) async {
    try {
      final normalizedUsername = username.trim();
      // Tìm employee theo username trong Firestore
      final employee = await _firestoreService.getEmployeeByUsername(
        normalizedUsername,
      );

      if (employee != null) {
        // Tìm thấy employee trong Firestore
        final isPasswordValid = _passwordService.verifyPassword(
          password,
          employee.password,
        );
        if (!isPasswordValid) {
          debugPrint('Invalid password for user: $normalizedUsername');
          return false;
        }

        // Kiểm tra tài khoản có đang active không
        if (!employee.isActive) {
          debugPrint('Account is locked: $username');
          return false;
        }

        // Đăng nhập thành công từ Firestore
        _role = employee.role;
        _username = employee.username;
        _employeeId = employee.id;
        _currentEmployee = employee;
        notifyListeners();

        debugPrint(
          'Login successful from Firestore: username=$normalizedUsername, role=${employee.role.name}, employeeId=${employee.id}',
        );

        if (!_passwordService.isHashed(employee.password)) {
          final hashedPassword = _passwordService.hashPassword(password);
          try {
            await _firestoreService.updateEmployee(
              employee.copyWith(
                password: hashedPassword,
                updatedAt: DateTime.now(),
              ),
            );
          } catch (e, stackTrace) {
            _errorHandler.logError(
              e,
              stackTrace,
              context: 'Failed to migrate password hash for $normalizedUsername',
            );
          }
        }

        return true;
      }

      // Fallback: Kiểm tra các tài khoản demo (nếu không tìm thấy trong Firestore)
      debugPrint(
        'Employee not found in Firestore, checking demo accounts: $normalizedUsername',
      );
      return _loginDemoAccount(normalizedUsername, password);
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace,
        context: 'Error during login',
      );
      // Nếu có lỗi với Firestore, thử đăng nhập với tài khoản demo
      return _loginDemoAccount(username.trim(), password);
    }
  }

  // Đăng nhập với tài khoản demo (fallback)
  bool _loginDemoAccount(String username, String password) {
    // Tài khoản demo: staff/1234, manager/1234
    if (username == 'staff' && password == '1234') {
      _role = UserRole.staff;
      _username = username;
      _employeeId = 'staff';
      _currentEmployee = null; // Không có trong Firestore
      notifyListeners();
      debugPrint('Login successful with demo account: staff');
      return true;
    }

    if (username == 'manager' && password == '1234') {
      _role = UserRole.manager;
      _username = username;
      _employeeId = 'manager';
      _currentEmployee = null; // Không có trong Firestore
      notifyListeners();
      debugPrint('Login successful with demo account: manager');
      return true;
    }

    return false;
  }

  void logout() {
    _role = null;
    _username = null;
    _employeeId = null;
    _currentEmployee = null;
    notifyListeners();
  }
}
