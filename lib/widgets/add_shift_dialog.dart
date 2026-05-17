import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shift_model.dart';
import '../models/employee_model.dart';
import '../models/enums.dart';
import '../providers/restaurant_provider.dart';
import '../providers/app_strings.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../services/error_handler.dart';
import '../utils/input_sanitizer.dart';

/// Khung giờ mặc định: Sáng / Chiều / Tối (nhận diện bằng icon + màu).
enum _ShiftTimeSlot {
  morning(
    TimeOfDay(hour: 6, minute: 30),
    TimeOfDay(hour: 11, minute: 30),
    Icons.wb_sunny_rounded,
    0xFFE65100,
  ),
  afternoon(
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 17, minute: 30),
    Icons.wb_cloudy_rounded,
    0xFF1E88E5,
  ),
  evening(
    TimeOfDay(hour: 17, minute: 30),
    TimeOfDay(hour: 23, minute: 30),
    Icons.nights_stay_rounded,
    0xFF4527A0,
  );

  const _ShiftTimeSlot(this.start, this.end, this.icon, this.accentArgb);
  final TimeOfDay start;
  final TimeOfDay end;
  final IconData icon;
  final int accentArgb;

  Color get accent => Color(accentArgb);

  String label(AppStrings s) => switch (this) {
        morning => s.shiftPresetMorning,
        afternoon => s.shiftPresetAfternoon,
        evening => s.shiftPresetEvening,
      };

  String timeRangeLabel() {
    String t(TimeOfDay x) =>
        '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
    return '${t(start)} – ${t(end)}';
  }
}

_ShiftTimeSlot? _matchPreset(TimeOfDay start, TimeOfDay end) {
  for (final slot in _ShiftTimeSlot.values) {
    if (start.hour == slot.start.hour &&
        start.minute == slot.start.minute &&
        end.hour == slot.end.hour &&
        end.minute == slot.end.minute) {
      return slot;
    }
  }
  return null;
}

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
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  final _notesController = TextEditingController();
  final ErrorHandler _errorHandler = ErrorHandler();
  final Map<String, String> _employeeNamesById = {};

  /// Thứ Hai của tuần đang chọn (chỉ giao diện tạo mới theo tuần).
  late DateTime _batchWeekMonday;
  final Set<int> _batchSelectedWeekdays = <int>{};

  /// Khớp một trong ba khung giờ gợi ý; null nếu giờ tùy chỉnh.
  _ShiftTimeSlot? _activeTimeSlot;

  @override
  void initState() {
    super.initState();
    final anchor = widget.shiftToEdit?.date ?? DateTime.now();
    _batchWeekMonday = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(Duration(days: anchor.weekday - 1));
    if (widget.shiftToEdit != null) {
      final shift = widget.shiftToEdit!;
      _selectedDate = shift.date;
      _startTime = shift.startTime;
      _endTime = shift.endTime;
      _notesController.text = shift.notes ?? '';
      _selectedEmployeeId = shift.openSlot ? null : shift.employeeId;
      _batchSelectedWeekdays
        ..clear()
        ..add(anchor.weekday);
    } else {
      _batchSelectedWeekdays
        ..clear()
        ..addAll({1, 2, 3, 4, 5});
    }
    _activeTimeSlot = _matchPreset(_startTime, _endTime);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Ngày làm việc sẽ ghi xuống Firestore (một ngày khi sửa; nhiều ngày khi tạo theo tuần).
  List<DateTime> _datesForSave() {
    if (widget.shiftToEdit != null) {
      return [
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      ];
    }
    if (_batchSelectedWeekdays.isEmpty) return [];
    final base = DateTime(
      _batchWeekMonday.year,
      _batchWeekMonday.month,
      _batchWeekMonday.day,
    );
    final sorted = _batchSelectedWeekdays.toList()..sort();
    return sorted.map((w) => base.add(Duration(days: w - 1))).toList();
  }

  Widget _buildTimePresetSection(BuildContext context) {
    final s = context.strings;
    final slots = _ShiftTimeSlot.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: AppTheme.primaryOrange),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                s.shiftPresetSectionTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _presetTile(slots[i], s)),
            ],
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _presetTile(_ShiftTimeSlot slot, AppStrings s) {
    final selected = _activeTimeSlot == slot;
    final accent = slot.accent;

    final accentBold = Color.lerp(accent, Colors.black, 0.22) ?? accent;
    final bgColor = selected
        ? accent.withValues(alpha: 0.32)
        : Color.alphaBlend(accent.withValues(alpha: 0.06), Colors.grey.shade50);
    final borderColor = selected
        ? accentBold
        : accent.withValues(alpha: 0.22);
    final borderWidth = selected ? 2.0 : 1.0;
    final iconColor = selected ? accentBold : accent.withValues(alpha: 0.42);
    final titleColor = selected ? accentBold : accent.withValues(alpha: 0.48);
    final timeColor = selected ? Colors.grey.shade900 : Colors.grey.shade500;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          setState(() {
            _startTime = slot.start;
            _endTime = slot.end;
            _activeTimeSlot = slot;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(slot.icon, color: iconColor, size: selected ? 22 : 18),
              const SizedBox(height: 2),
              Text(
                slot.label(s),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: selected ? 11 : 10,
                  color: titleColor,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${slot.timeRangeLabel()} · ${s.shiftPresetDurationAbbr}',
                  style: TextStyle(
                    fontSize: 9,
                    color: timeColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchWeekSection(BuildContext context) {
    final s = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: s.previousWeek,
              onPressed: () {
                setState(() {
                  _batchWeekMonday =
                      _batchWeekMonday.subtract(const Duration(days: 7));
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                s.shiftBatchWeekRangeLabel(_batchWeekMonday),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: s.nextWeek,
              onPressed: () {
                setState(() {
                  _batchWeekMonday =
                      _batchWeekMonday.add(const Duration(days: 7));
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          s.shiftBatchSelectDays,
          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (int w = 1; w <= 7; w++)
              FilterChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                label: Text(
                  s.getWeekdayAbbr(w),
                  style: const TextStyle(fontSize: 11),
                ),
                selected: _batchSelectedWeekdays.contains(w),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _batchSelectedWeekdays.add(w);
                    } else {
                      _batchSelectedWeekdays.remove(w);
                    }
                  });
                },
                selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.25),
                checkmarkColor: AppTheme.primaryOrange,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 0,
          runSpacing: 0,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _batchSelectedWeekdays
                    ..clear()
                    ..addAll({1, 2, 3, 4, 5, 6, 7});
                });
              },
              child: Text(s.shiftBatchSelectAll, style: const TextStyle(fontSize: 12)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _batchSelectedWeekdays
                    ..clear()
                    ..addAll({1, 2, 3, 4, 5});
                });
              },
              child: Text(s.shiftBatchSelectWeekdays, style: const TextStyle(fontSize: 12)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _batchSelectedWeekdays
                    ..clear()
                    ..addAll({6, 7});
                });
              },
              child: Text(s.shiftBatchSelectWeekend, style: const TextStyle(fontSize: 12)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(_batchSelectedWeekdays.clear);
              },
              child: Text(s.shiftBatchClearDays, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannedDays = widget.shiftToEdit != null
        ? 1
        : _batchSelectedWeekdays.length;

    final screenH = MediaQuery.sizeOf(context).height;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      title: widget.shiftToEdit == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.strings.addNewShift,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  context.strings.shiftBatchCreateHint,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[700],
                    height: 1.25,
                  ),
                ),
              ],
            )
          : Text(
              context.strings.editShift,
              style: const TextStyle(fontSize: 18),
            ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min(MediaQuery.sizeOf(context).width - 28, 620),
          maxHeight: screenH * 0.78,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final provider = Provider.of<RestaurantProvider>(context);
                    return StreamBuilder<List<EmployeeModel>>(
                      stream: provider.getEmployeesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            (snapshot.data == null || snapshot.data!.isEmpty)) {
                          return const LinearProgressIndicator(minHeight: 2);
                        }

                        final allEmployees = snapshot.data ?? [];
                        final employeesMap = <String, EmployeeModel>{};
                        for (var emp in allEmployees) {
                          if (emp.isActive && !employeesMap.containsKey(emp.id)) {
                            employeesMap[emp.id] = emp;
                          }
                        }
                        final employees = employeesMap.values.toList();
                        for (final emp in employees) {
                          _employeeNamesById[emp.id] = emp.name;
                        }

                        if (employees.isNotEmpty) {
                          final validCurrent = _selectedEmployeeId != null &&
                              employees.any((e) => e.id == _selectedEmployeeId);
                          if (!validCurrent) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() {
                                _selectedEmployeeId = employees.first.id;
                              });
                            });
                          }
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedEmployeeId,
                          decoration: InputDecoration(
                            labelText: context.strings.employeeLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: employees
                              .map(
                                (emp) => DropdownMenuItem<String>(
                                  value: emp.id,
                                  child: Text(emp.name),
                                ),
                              )
                              .toList(),
                          onChanged: employees.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedEmployeeId = value;
                                  });
                                },
                          validator: (value) {
                            if (employees.isEmpty) {
                              return 'Chưa có nhân viên khả dụng';
                            }
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
                const SizedBox(height: 10),

                if (widget.shiftToEdit != null)
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
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  )
                else
                  _buildBatchWeekSection(context),
                const SizedBox(height: 10),

                _buildTimePresetSection(context),

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
                              _activeTimeSlot = _matchPreset(_startTime, _endTime);
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.strings.startTimeLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            suffixIcon: const Icon(Icons.access_time, size: 20),
                          ),
                          child: Text(
                            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                              _activeTimeSlot = _matchPreset(_startTime, _endTime);
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.strings.endTimeLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            suffixIcon: const Icon(Icons.access_time, size: 20),
                          ),
                          child: Text(
                            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: context.strings.notesLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
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
            final strings = AppStrings(
              Provider.of<LanguageProvider>(context, listen: false).language,
            );
            FocusManager.instance.primaryFocus?.unfocus();
            await Future<void>.delayed(Duration.zero);
            if (!context.mounted) return;

            if (!_formKey.currentState!.validate()) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text(strings.formValidationFailed),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (!_isValidShiftTime()) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.shiftEndAfterStart),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final dates = _datesForSave();
            if (widget.shiftToEdit == null && dates.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.shiftBatchNeedOneDay),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final provider = Provider.of<RestaurantProvider>(
              context,
              listen: false,
            );
            final notesSanitized =
                InputSanitizer.sanitizeNotes(_notesController.text);
            final notes = notesSanitized.isEmpty ? null : notesSanitized;
            final selectedId = _selectedEmployeeId;
            if (selectedId == null || selectedId.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.selectEmployeeRequired),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final overlappingById = <String, ShiftModel>{};
            for (final d in dates) {
              final o = await provider.checkOverlappingShifts(
                selectedId,
                d,
                _startTime,
                _endTime,
                excludeShiftId: widget.shiftToEdit?.id,
              );
              for (final s in o) {
                overlappingById[s.id] = s;
              }
            }
            final overlappingShifts = overlappingById.values.toList();

            if (!context.mounted) return;
            if (overlappingShifts.isNotEmpty) {
              final shouldContinue = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  final dlgStrings = dialogContext.strings;
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
                            dlgStrings.shiftOverlapWarning,
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
                          dlgStrings.employeeHasOverlappingShift,
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
                                  '${shift.date.day}/${shift.date.month}/${shift.date.year} · ${_formatTime(shift.startTime)} – ${_formatTime(shift.endTime)}',
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
                          dlgStrings.continueAddingShift,
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
                        child: Text(dlgStrings.cancelButton),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(dlgStrings.addAnyway),
                      ),
                    ],
                  );
                },
              );

              if (shouldContinue != true || !context.mounted) {
                return;
              }
            }

            if (!context.mounted) return;

            try {
              final employeeName =
                  _employeeNamesById[selectedId] ?? 'Nhân viên';

              final shifts = dates
                  .map(
                    (d) => ShiftModel(
                      id: widget.shiftToEdit?.id ?? '',
                      employeeId: selectedId,
                      employeeName: employeeName,
                      date: DateTime(d.year, d.month, d.day),
                      startTime: _startTime,
                      endTime: _endTime,
                      status: widget.shiftToEdit?.status ?? ShiftStatus.scheduled,
                      notes: notes,
                    ),
                  )
                  .toList();

              if (!context.mounted) return;
              Navigator.pop(context, shifts);
            } catch (e, stackTrace) {
              final message = _errorHandler.getUserMessage(
                e,
                fallbackMessage: 'Lỗi khi lấy thông tin nhân viên',
              );
              _errorHandler.logError(
                e,
                stackTrace,
                context: 'Error loading employee for shift',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: Text(
            widget.shiftToEdit != null
                ? context.strings.saveButton
                : context.strings.saveBatchButton(
                    plannedDays == 0 ? 1 : plannedDays,
                  ),
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isValidShiftTime() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes > startMinutes;
  }
}
