import 'package:do_an_mon_quanlyquanan/models/employee_model.dart';
import 'package:do_an_mon_quanlyquanan/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmployeeModel role mapping (auth-adjacent rules)', () {
    test('maps waiter role to staff for backward compatibility', () {
      final employee = EmployeeModel.fromFirestore('e1', {
        'username': 'waiter1',
        'name': 'Waiter 1',
        'password': '1234',
        'role': 'waiter',
        'isActive': true,
      });

      expect(employee.role, UserRole.staff);
    });

    test('maps unknown role safely to staff', () {
      final employee = EmployeeModel.fromFirestore('e2', {
        'username': 'legacy',
        'name': 'Legacy User',
        'password': '1234',
        'role': 'unknown_role',
        'isActive': true,
      });

      expect(employee.role, UserRole.staff);
    });

    test('preserves manager and cashier roles from firestore', () {
      final manager = EmployeeModel.fromFirestore('m1', {
        'username': 'manager1',
        'name': 'Manager 1',
        'password': '1234',
        'role': 'manager',
        'isActive': true,
      });
      final cashier = EmployeeModel.fromFirestore('c1', {
        'username': 'cashier1',
        'name': 'Cashier 1',
        'password': '1234',
        'role': 'cashier',
        'isActive': true,
      });

      expect(manager.role, UserRole.manager);
      expect(cashier.role, UserRole.cashier);
    });
  });
}
