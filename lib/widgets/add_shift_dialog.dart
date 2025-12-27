import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shift_model.dart';
import '../models/employee_model.dart';
import '../models/enums.dart';
import '../providers/restaurant_provider.dart';
import '../providers/app_strings.dart';
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
    return AlertDialog(
      title: Text(
        widget.shiftToEdit == null
            ? context.strings.addNewShift
            : context.strings.editShift,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Employee selection
              Builder(
                builder: (context) {
                  final provider = Provider.of<RestaurantProvider>(context);
                  return StreamBuilder<List<EmployeeModel>>(
                    stream: provider.getEmployeesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Reset selection khi đang loading để tránh lỗi assertion
                        if (_selectedEmployeeId != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedEmployeeId = null;
                              });
                            }
                          });
                        }
                        return DropdownButtonFormField<String>(
                          value: null,
                          decoration: const InputDecoration(
                            labelText: 'Đang tải nhân viên...',
                            border: OutlineInputBorder(),
                          ),
                          items: [],
                          onChanged: (_) {},
                        );
                      }

                      if (snapshot.hasError) {
                        // Reset selection khi có lỗi
                        if (_selectedEmployeeId != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedEmployeeId = null;
                              });
                            }
                          });
                        }
                        return DropdownButtonFormField<String>(
                          value: null,
                          decoration: const InputDecoration(
                            labelText: 'Lỗi khi tải nhân viên',
                            border: OutlineInputBorder(),
                          ),
                          items: [],
                          onChanged: (_) {},
                        );
                      }

                      final allEmployees = snapshot.data ?? [];
                      // Chỉ lấy nhân viên đang hoạt động và loại bỏ duplicate IDs
                      final employeesMap = <String, EmployeeModel>{};
                      for (var emp in allEmployees) {
                        if (emp.isActive && !employeesMap.containsKey(emp.id)) {
                          employeesMap[emp.id] = emp;
                        }
                      }
                      final employees = employeesMap.values.toList();

                      if (employees.isEmpty) {
                        // Reset selection nếu không có nhân viên
                        if (_selectedEmployeeId != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedEmployeeId = null;
                              });
                            }
                          });
                        }
                        return DropdownButtonFormField<String>(
                          value: null,
                          decoration: const InputDecoration(
                            labelText: 'Chưa có nhân viên',
                            border: OutlineInputBorder(),
                          ),
                          items: [],
                          onChanged: (_) {},
                        );
                      }

                      // Tạo danh sách items và đảm bảo không có duplicate values
                      final items = employees.map((emp) {
                        return DropdownMenuItem<String>(
                          value: emp.id,
                          child: Text(emp.name),
                        );
                      }).toList();

                      // Đảm bảo _selectedEmployeeId có trong danh sách employees
                      // Nếu không, set về null (khi đang edit nhưng employee không còn active)
                      final validEmployeeId =
                          _selectedEmployeeId != null &&
                              employees.any(
                                (emp) => emp.id == _selectedEmployeeId,
                              )
                          ? _selectedEmployeeId
                          : null;

                      // Nếu đang edit nhưng employee không còn trong danh sách, reset về null
                      if (widget.shiftToEdit != null &&
                          validEmployeeId == null &&
                          _selectedEmployeeId != null) {
                        // Employee cũ không còn active, reset selection
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedEmployeeId = null;
                            });
                          }
                        });
                      }

                      return DropdownButtonFormField<String>(
                        value: validEmployeeId,
                        decoration: InputDecoration(
                          labelText: context.strings.employeeLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: items,
                        onChanged: (value) {
                          setState(() {
                            _selectedEmployeeId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.strings.selectEmployeeRequired;
                          }
                          return null;
                        },
                      );
                    },
                  );
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
                  decoration: InputDecoration(
                    labelText: context.strings.workDayLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
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
                        decoration: InputDecoration(
                          labelText: context.strings.startTimeLabel,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.access_time),
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
                        decoration: InputDecoration(
                          labelText: context.strings.endTimeLabel,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.access_time),
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
              Builder(
                builder: (context) {
                  final strings = context.strings;
                  return DropdownButtonFormField<ShiftStatus>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: strings.tableStatusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: ShiftStatus.values.map((status) {
                      String label;
                      switch (status) {
                        case ShiftStatus.scheduled:
                          label = strings.shiftScheduled;
                          break;
                        case ShiftStatus.completed:
                          label = strings.shiftCompleted;
                          break;
                        case ShiftStatus.cancelled:
                          label = strings.shiftCancelled;
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
                  );
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: context.strings.notesLabel,
                  border: const OutlineInputBorder(),
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
          child: Text(context.strings.cancelButton),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final provider = Provider.of<RestaurantProvider>(
                context,
                listen: false,
              );
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
                  builder: (dialogContext) {
                    final strings = dialogContext.strings;
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.orange[700],
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings.shiftOverlapWarning,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.employeeHasOverlappingShift,
                            style: const TextStyle(fontSize: 14),
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
                                  if (shift.notes != null &&
                                      shift.notes!.isNotEmpty)
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
                          Text(
                            strings.continueAddingShift,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(strings.cancelButton),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                          ),
                          child: Text(strings.addAnyway),
                        ),
                      ],
                    );
                  },
                );

                if (shouldContinue != true || !mounted) {
                  return; // User cancelled or widget disposed
                }
              }

              if (!mounted) return;

              // Get employee name from stream
              try {
                final employeesSnapshot = await provider
                    .getEmployeesStream()
                    .first
                    .timeout(const Duration(seconds: 5));
                final allEmployees = employeesSnapshot;
                final employee = allEmployees.firstWhere(
                  (emp) => emp.id == _selectedEmployeeId && emp.isActive,
                  orElse: () => throw Exception(
                    'Không tìm thấy nhân viên với ID: $_selectedEmployeeId',
                  ),
                );

                final shift = ShiftModel(
                  id: widget.shiftToEdit?.id ?? '',
                  employeeId: _selectedEmployeeId!,
                  employeeName: employee.name,
                  date: _selectedDate,
                  startTime: _startTime,
                  endTime: _endTime,
                  status: _status,
                  notes: _notesController.text.isEmpty
                      ? null
                      : _notesController.text,
                );

                Navigator.pop(context, shift);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi lấy thông tin nhân viên: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: Text(context.strings.saveButton),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
