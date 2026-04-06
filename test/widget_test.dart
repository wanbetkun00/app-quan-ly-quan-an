import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:do_an_mon_quanlyquanan/models/enums.dart';
import 'package:do_an_mon_quanlyquanan/providers/auth_provider.dart';
import 'package:do_an_mon_quanlyquanan/widgets/role_guard.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider(this._role);

  final UserRole? _role;

  @override
  UserRole? get role => _role;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('RBAC smoke test for manager-only screen', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthProvider(UserRole.staff);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(
          home: RoleGuard(
            allowedRoles: [UserRole.manager],
            child: Text('MANAGER_DASHBOARD'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MANAGER_DASHBOARD'), findsNothing);
    expect(find.text('Không đủ quyền'), findsOneWidget);
  });
}
