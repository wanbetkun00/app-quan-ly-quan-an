import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final String message;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.message = 'Bạn không có quyền truy cập chức năng này.',
  });

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((auth) => auth.role);
    if (role != null && allowedRoles.contains(role)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Không đủ quyền')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
