import 'package:do_an_mon_quanlyquanan/models/enums.dart';
import 'package:do_an_mon_quanlyquanan/providers/auth_provider.dart';
import 'package:do_an_mon_quanlyquanan/widgets/role_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider(this._role);

  final UserRole? _role;

  @override
  UserRole? get role => _role;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _appWithAuth(AuthProvider auth, Widget child) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('RoleGuard', () {
    testWidgets('renders child when role is allowed', (tester) async {
      final auth = FakeAuthProvider(UserRole.manager);

      await tester.pumpWidget(
        _appWithAuth(
          auth,
          const RoleGuard(
            allowedRoles: [UserRole.manager],
            child: Text('MANAGER_SCREEN'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('MANAGER_SCREEN'), findsOneWidget);
      expect(find.text('Không đủ quyền'), findsNothing);
    });

    testWidgets('renders access denied scaffold when role is not allowed', (
      tester,
    ) async {
      final auth = FakeAuthProvider(UserRole.staff);

      await tester.pumpWidget(
        _appWithAuth(
          auth,
          const RoleGuard(
            allowedRoles: [UserRole.manager],
            child: Text('MANAGER_SCREEN'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('MANAGER_SCREEN'), findsNothing);
      expect(find.text('Không đủ quyền'), findsOneWidget);
    });

    testWidgets('renders access denied when not logged in', (tester) async {
      final auth = FakeAuthProvider(null);

      await tester.pumpWidget(
        _appWithAuth(
          auth,
          const RoleGuard(
            allowedRoles: [UserRole.manager],
            child: Text('MANAGER_SCREEN'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('MANAGER_SCREEN'), findsNothing);
      expect(find.text('Không đủ quyền'), findsOneWidget);
    });
  });
}
