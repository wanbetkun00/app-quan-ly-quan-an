import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shift_model.dart';
import '../models/enums.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';

class AddShiftDialog extends StatefulWidget {
  final ShiftModel? shiftToEdit;

  const AddShiftDialog({super.key, this.shiftToEdit});

  @override
  State<AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<AddShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  ShiftStatus _status = ShiftStatus.scheduled;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.shiftToEdit != null) {
      final shift = widget.shiftToEdit!;
      _selectedEmployeeId = shift.employeeId;
      _selectedDate = shift.date;
      _startTime = shift.startTime;
      _endTime = shift.endTime;
      _status = shift.status;
      _notesController.text = shift.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);

    return AlertDialog(
      title: Text(widget.shiftToEdit == null ? 'Thêm ca làm mới' : 'Sửa ca làm'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Employee selection
              DropdownButtonFormField<String>(
                value: _selectedEmployeeId,
                decoration: const InputDecoration(
                  labelText: 'Nhân viên',
                  border: OutlineInputBorder(),
                ),
                items: provider.employees.map((emp) {
                  return DropdownMenuItem<String>(
                    value: emp['id'],
                    child: Text(emp['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEmployeeId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn nhân viên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày làm việc',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Giờ bắt đầu',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _endTime = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Giờ kết thúc',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<ShiftStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: ShiftStatus.values.map((status) {
                  String label = 'Đã lên lịch';
                  switch (status) {
                    case ShiftStatus.scheduled:
                      label = 'Đã lên lịch';
                      break;
                    case ShiftStatus.completed:
                      label = 'Đã hoàn thành';
                      break;
                    case ShiftStatus.cancelled:
                      label = 'Đã hủy';
                      break;
                  }
                  return DropdownMenuItem<ShiftStatus>(
                    value: status,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              // Check for overlapping shifts
              final overlappingShifts = await provider.checkOverlappingShifts(
                _selectedEmployeeId!,
                _selectedDate,
                _startTime,
                _endTime,
                excludeShiftId: widget.shiftToEdit?.id,
              );

              if (overlappingShifts.isNotEmpty && mounted) {
                // Show warning dialog
                final shouldContinue = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700], size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Cảnh báo trùng ca làm',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nhân viên này đã có ca làm trùng với thời gian bạn chọn:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ...overlappingShifts.map((shift) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (shift.notes != null && shift.notes!.isNotEmpty)
                                  Text(
                                    shift.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        const Text(
                          'Bạn có muốn tiếp tục thêm ca làm này không?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Vẫn thêm'),
                      ),
                    ],
                  ),
                );

                if (shouldContinue != true) {
                  return; // User cancelled
                }
              }

              if (mounted) {
                final employee = provider.employees.firstWhere(
                  (emp) => emp['id'] == _selectedEmployeeId,
                );

                final shift = ShiftModel(
                  id: widget.shiftToEdit?.id ?? '',
                  employeeId: _selectedEmployeeId!,
                  employeeName: employee['name']!,
                  date: _selectedDate,
                  startTime: _startTime,
                  endTime: _endTime,
                  status: _status,
                  notes: _notesController.text.isEmpty ? null : _notesController.text,
                );

                Navigator.pop(context, shift);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

