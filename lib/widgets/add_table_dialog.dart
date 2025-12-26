import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../providers/app_strings.dart';

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
          SnackBar(
            content: Text(context.strings.validIdRequired),
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
                  widget.tableToEdit == null
                      ? context.strings.addNewTable
                      : context.strings.editTableInfo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ID Field
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: context.strings.tableNumberLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                    helperText: context.strings.tableNumberHelper,
                  ),
                  keyboardType: TextInputType.number,
                  enabled:
                      widget.tableToEdit == null, // Không cho sửa ID khi edit
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.strings.tableNumberRequired;
                    }
                    final id = int.tryParse(value.trim());
                    if (id == null || id <= 0) {
                      return context.strings.tableNumberInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.strings.tableNameLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.table_restaurant),
                    helperText: context.strings.tableNameExample,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.strings.tableNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<TableStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: context.strings.tableStatusLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.info),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: TableStatus.available,
                      child: Text(context.strings.tableStatusAvailable),
                    ),
                    DropdownMenuItem(
                      value: TableStatus.occupied,
                      child: Text(context.strings.tableStatusOccupied),
                    ),
                    DropdownMenuItem(
                      value: TableStatus.paymentPending,
                      child: Text(context.strings.tableStatusPaymentPending),
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
                        child: Text(context.strings.cancelButton),
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
                        child: Text(
                          widget.tableToEdit == null
                              ? context.strings.addTableButton
                              : context.strings.updateButton,
                        ),
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
