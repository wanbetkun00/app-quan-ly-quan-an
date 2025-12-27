import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee_model.dart';
import '../../models/enums.dart';
import '../../providers/restaurant_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_employee_dialog.dart';

class EmployeeManagementScreen extends StatelessWidget {
  const EmployeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEmployeeDialog(context, provider),
            tooltip: 'Thêm nhân viên mới',
          ),
        ],
      ),
      body: StreamBuilder<List<EmployeeModel>>(
        stream: provider.getEmployeesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi khi tải danh sách nhân viên: ${snapshot.error}'),
            );
          }

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhân viên nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEmployeeDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm nhân viên đầu tiên'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.getEmployees();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return _buildEmployeeCard(context, employee, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    EmployeeModel employee,
    RestaurantProvider provider,
  ) {
    final roleColor = employee.role == UserRole.manager
        ? AppTheme.primaryOrange
        : AppTheme.darkGreyText;
    final roleText = employee.role == UserRole.manager
        ? 'Quản lý'
        : 'Nhân viên';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: roleColor, width: 2),
          ),
          child: Icon(
            employee.role == UserRole.manager
                ? Icons.admin_panel_settings
                : Icons.person,
            color: roleColor,
          ),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  employee.username,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleText,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!employee.isActive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đã khóa',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'edit') {
              await _showEditEmployeeDialog(context, employee, provider);
            } else if (value == 'toggle') {
              await _toggleEmployeeStatus(context, employee, provider);
            } else if (value == 'delete') {
              await _showDeleteDialog(context, employee, provider);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Sửa'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    employee.isActive ? Icons.lock : Icons.lock_open,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(employee.isActive ? 'Khóa tài khoản' : 'Mở khóa'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEmployeeDialog(
    BuildContext context,
    RestaurantProvider provider,
  ) async {
    final result = await showDialog<EmployeeModel>(
      context: context,
      builder: (context) => const AddEmployeeDialog(),
    );
    if (result != null && context.mounted) {
      final success = await provider.addEmployee(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã thêm nhân viên "${result.name}"'
                  : 'Lỗi khi thêm nhân viên',
            ),
            backgroundColor: success
                ? AppTheme.statusGreen
                : AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _showEditEmployeeDialog(
    BuildContext context,
    EmployeeModel employee,
    RestaurantProvider provider,
  ) async {
    final result = await showDialog<EmployeeModel>(
      context: context,
      builder: (context) => AddEmployeeDialog(employeeToEdit: employee),
    );
    if (result != null && context.mounted) {
      final success = await provider.updateEmployee(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã cập nhật nhân viên "${result.name}"'
                  : 'Lỗi khi cập nhật nhân viên',
            ),
            backgroundColor: success
                ? AppTheme.statusGreen
                : AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleEmployeeStatus(
    BuildContext context,
    EmployeeModel employee,
    RestaurantProvider provider,
  ) async {
    final updated = employee.copyWith(
      isActive: !employee.isActive,
      updatedAt: DateTime.now(),
    );
    final success = await provider.updateEmployee(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã ${employee.isActive ? 'khóa' : 'mở khóa'} tài khoản "${employee.name}"'
                : 'Lỗi khi cập nhật trạng thái',
          ),
          backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    EmployeeModel employee,
    RestaurantProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa nhân viên "${employee.name}"?\n\nLưu ý: Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteEmployee(employee.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã xóa nhân viên "${employee.name}"'
                  : 'Lỗi khi xóa nhân viên',
            ),
            backgroundColor: success
                ? AppTheme.statusGreen
                : AppTheme.statusRed,
          ),
        );
      }
    }
  }
}
