import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AddTableDialog extends StatefulWidget {
  final TableModel? tableToEdit;
  
  const AddTableDialog({super.key, this.tableToEdit});

  @override
  State<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  TableStatus _selectedStatus = TableStatus.available;

  @override
  void initState() {
    super.initState();
    if (widget.tableToEdit != null) {
      final table = widget.tableToEdit!;
      _nameController.text = table.name;
      _idController.text = table.id.toString();
      _selectedStatus = table.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final id = int.tryParse(_idController.text.trim());
      
      if (id == null || id <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập ID hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final table = TableModel(
        id: id,
        name: name,
        status: _selectedStatus,
        currentOrderId: widget.tableToEdit?.currentOrderId,
      );

      Navigator.of(context).pop(table);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.tableToEdit == null ? 'Thêm bàn mới' : 'Sửa thông tin bàn',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // ID Field
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Số bàn (ID)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                    helperText: 'Số bàn phải là số nguyên dương',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: widget.tableToEdit == null, // Không cho sửa ID khi edit
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số bàn';
                    }
                    final id = int.tryParse(value.trim());
                    if (id == null || id <= 0) {
                      return 'Số bàn không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên bàn',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.table_restaurant),
                    helperText: 'Ví dụ: Bàn 1, T1, Table 1',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên bàn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Status Dropdown
                DropdownButtonFormField<TableStatus>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TableStatus.available,
                      child: Text('Trống'),
                    ),
                    DropdownMenuItem(
                      value: TableStatus.occupied,
                      child: Text('Đang dùng'),
                    ),
                    DropdownMenuItem(
                      value: TableStatus.paymentPending,
                      child: Text('Chờ thanh toán'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(widget.tableToEdit == null ? 'Thêm bàn' : 'Cập nhật'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

