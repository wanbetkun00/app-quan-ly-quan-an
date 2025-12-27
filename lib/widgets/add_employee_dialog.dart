import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeModel? employeeToEdit;

  const AddEmployeeDialog({super.key, this.employeeToEdit});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late UserRole _selectedRole;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.employeeToEdit?.name ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.employeeToEdit?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.employeeToEdit?.password ?? '',
    );
    _selectedRole = widget.employeeToEdit?.role ?? UserRole.staff;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employeeToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Sửa nhân viên' : 'Thêm nhân viên mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  prefixIcon: Icon(Icons.account_circle),
                  border: OutlineInputBorder(),
                ),
                enabled: !isEditing, // Không cho sửa username khi đang edit
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  if (value.length < 3) {
                    return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEditing
                      ? 'Mật khẩu mới (để trống nếu không đổi)'
                      : 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (!isEditing && (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value != null && value.isNotEmpty && value.length < 4) {
                    return 'Mật khẩu phải có ít nhất 4 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role selector
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(
                      role == UserRole.manager ? 'Quản lý' : 'Nhân viên',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final password = _passwordController.text.trim();
              // Nếu đang edit và không nhập password mới, giữ password cũ
              final finalPassword = isEditing && password.isEmpty
                  ? widget.employeeToEdit!.password
                  : password;

              final employee = EmployeeModel(
                id: widget.employeeToEdit?.id ?? '',
                username: _usernameController.text.trim(),
                name: _nameController.text.trim(),
                password: finalPassword,
                role: _selectedRole,
                isActive: widget.employeeToEdit?.isActive ?? true,
                createdAt: widget.employeeToEdit?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              Navigator.pop(context, employee);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }
}
