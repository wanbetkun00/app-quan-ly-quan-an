import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shift_model.dart';
import '../../models/employee_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_shift_dialog.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  DateTime _selectedWeek = DateTime.now();
  String? _selectedEmployeeId;
  bool _isDeletingAll = false;
  final ScrollController _matrixHorizontalController = ScrollController();
  static const double _slotColWidth = 140.0;
  static const double _minDayColWidth = 120.0;
  static const double _maxDayColWidth = 170.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _matrixHorizontalController.dispose();
    super.dispose();
  }

  static final List<_ShiftSlotDef> _slotDefs = [
    _ShiftSlotDef(
      id: 'morning',
      label: 'Sáng',
      range: '6:30 - 11:30',
      startHour: 6,
      startMinute: 30,
    ),
    _ShiftSlotDef(
      id: 'noon',
      label: 'Trưa',
      range: '11:30 - 17:30',
      startHour: 11,
      startMinute: 30,
    ),
    _ShiftSlotDef(
      id: 'evening',
      label: 'Chiều',
      range: '17:30 - 23:30',
      startHour: 17,
      startMinute: 30,
    ),
  ];

  String _slotIdForShift(ShiftModel shift) {
    final minutes = shift.startTime.hour * 60 + shift.startTime.minute;
    if (minutes < 11 * 60 + 30) return 'morning';
    if (minutes < 17 * 60 + 30) return 'noon';
    return 'evening';
  }

  List<DateTime> _weekDaysForSelected() {
    final m = _getWeekStart(_selectedWeek);
    return List.generate(
      7,
      (i) => DateTime(m.year, m.month, m.day).add(Duration(days: i)),
    );
  }

  void _setWeekAndSyncDayPage(DateTime newWeek) {
    setState(() {
      _selectedWeek = newWeek;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.badge_outlined,
                size: 18,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.strings.shiftManagementTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.strings.refresh,
            onPressed: () => provider.refreshShifts(),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            onSelected: (value) async {
              if (value == 'delete_all') {
                await _confirmAndDeleteAllShifts(context, provider);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete_all',
                enabled: !_isDeletingAll,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      size: 20,
                      color: _isDeletingAll ? Colors.grey : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isDeletingAll ? 'Đang xóa...' : 'Xóa tất cả ca làm',
                      style: TextStyle(
                        color: _isDeletingAll ? Colors.grey : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddShiftDialog(context, provider),
            tooltip: context.strings.addNewShift,
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    _setWeekAndSyncDayPage(
                      _selectedWeek.subtract(const Duration(days: 7)),
                    );
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedWeek,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        _setWeekAndSyncDayPage(picked);
                      }
                    },
                    child: Text(
                      _getWeekRangeText(_selectedWeek),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _setWeekAndSyncDayPage(
                      _selectedWeek.add(const Duration(days: 7)),
                    );
                  },
                ),
              ],
            ),
          ),

          // Employee filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(context.strings.filterByEmployee),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<List<EmployeeModel>>(
                    stream: provider.getEmployeesStream(),
                    builder: (context, snapshot) {
                      // Hiển thị loading nếu đang tải
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: Text(
                            'Lỗi khi tải nhân viên: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                          ),
                        );
                      }

                      final allEmployees = snapshot.data ?? [];
                      // Chỉ lấy nhân viên đang hoạt động và loại bỏ duplicate IDs
                      final employeesMap = <String, Map<String, String>>{};
                      for (var emp in allEmployees) {
                        if (emp.isActive && !employeesMap.containsKey(emp.id)) {
                          employeesMap[emp.id] = {
                            'id': emp.id,
                            'name': emp.name,
                          };
                        }
                      }
                      final employees = employeesMap.values.toList();

                      // Nếu không có nhân viên, hiển thị thông báo
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
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chưa có nhân viên. Vui lòng thêm nhân viên trong tab "Nhân viên"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Đảm bảo _selectedEmployeeId có trong danh sách employees
                      // Logic đúng: chỉ trả về _selectedEmployeeId nếu nó không null VÀ có trong danh sách
                      final validEmployeeId =
                          _selectedEmployeeId != null &&
                              employees.any(
                                (emp) => emp['id'] == _selectedEmployeeId,
                              )
                          ? _selectedEmployeeId
                          : null;

                      // Reset selection nếu employee không còn trong danh sách
                      if (_selectedEmployeeId != null &&
                          validEmployeeId == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedEmployeeId = null;
                            });
                          }
                        });
                      }

                      // Tạo danh sách items và đảm bảo không có duplicate values
                      final items = [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(context.strings.allEmployees),
                        ),
                        ...employees.map((emp) {
                          return DropdownMenuItem<String>(
                            value: emp['id'],
                            child: Text(emp['name'] ?? ''),
                          );
                        }),
                      ];

                      return DropdownButton<String>(
                        value: validEmployeeId,
                        isExpanded: true,
                        hint: Text(context.strings.allEmployees),
                        items: items,
                        onChanged: (value) {
                          setState(() {
                            _selectedEmployeeId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Shifts list
          Expanded(
            child: StreamBuilder<List<ShiftModel>>(
              stream: provider.getShiftsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${context.strings.errorLoading} ${snapshot.error}',
                    ),
                  );
                }

                final allShifts = snapshot.data ?? [];
                final weekDays = _weekDaysForSelected();
                final weekStart = weekDays.first;
                final weekEnd = weekDays.last;

                final weekShifts = allShifts.where((shift) {
                  final shiftDate = DateTime(
                    shift.date.year,
                    shift.date.month,
                    shift.date.day,
                  );
                  return !shiftDate.isBefore(weekStart) &&
                      !shiftDate.isAfter(weekEnd);
                }).toList();

                final filteredShifts = _selectedEmployeeId == null
                    ? weekShifts
                    : weekShifts
                          .where(
                            (shift) => shift.involvesEmployee(
                              _selectedEmployeeId!,
                            ),
                          )
                          .toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = (constraints.maxWidth - 16).clamp(
                      0,
                      double.infinity,
                    );
                    final dayColWidth = ((availableWidth - _slotColWidth) /
                            weekDays.length)
                        .clamp(_minDayColWidth, _maxDayColWidth)
                        .toDouble();
                    final totalWidth =
                        _slotColWidth + (dayColWidth * weekDays.length);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: _buildStickyHorizontalScrollbar(totalWidth),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildShiftMatrix(
                                context,
                                provider,
                                weekDays,
                                filteredShifts,
                                dayColWidth: dayColWidth,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftMatrix(
    BuildContext context,
    RestaurantProvider provider,
    List<DateTime> weekDays,
    List<ShiftModel> shifts, {
    required double dayColWidth,
  }) {
    final now = DateTime.now();

    final matrix = <String, List<ShiftModel>>{};
    for (final shift in shifts) {
      final d = DateTime(shift.date.year, shift.date.month, shift.date.day);
      final key = '${d.toIso8601String()}_${_slotIdForShift(shift)}';
      matrix.putIfAbsent(key, () => []).add(shift);
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: SingleChildScrollView(
          controller: _matrixHorizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _slotColWidth + (dayColWidth * weekDays.length),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildMatrixHeaderCell(
                      width: _slotColWidth,
                      title: 'Ca làm',
                      subtitle: 'Khung giờ',
                    ),
                    ...weekDays.map((day) {
                      final isToday = day.year == now.year &&
                          day.month == now.month &&
                          day.day == now.day;
                      return _buildMatrixHeaderCell(
                        width: dayColWidth,
                        title: _weekdayLabel(day.weekday),
                        subtitle: '${day.day}/${day.month}',
                        isToday: isToday,
                      );
                    }),
                  ],
                ),
                const Divider(height: 1),
                ..._slotDefs.map((slot) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSlotLabelCell(_slotColWidth, slot),
                          ...weekDays.map((day) {
                            final d = DateTime(day.year, day.month, day.day);
                            final key = '${d.toIso8601String()}_${slot.id}';
                            final slotShifts = matrix[key] ?? [];
                            final isToday = day.year == now.year &&
                                day.month == now.month &&
                                day.day == now.day;
                            return _buildShiftStaffCell(
                              context,
                              provider: provider,
                              width: dayColWidth,
                              shifts: slotShifts,
                              isTodayColumn: isToday,
                            );
                          }),
                        ],
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildStickyHorizontalScrollbar(double contentWidth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.grey.withValues(alpha: 0.08),
        height: 14,
        child: Scrollbar(
          controller: _matrixHorizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: _matrixHorizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: contentWidth, height: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixHeaderCell({
    required double width,
    required String title,
    required String subtitle,
    bool isToday = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: isToday
          ? AppTheme.primaryOrange.withValues(alpha: 0.12)
          : Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isToday ? AppTheme.primaryOrange : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotLabelCell(double width, _ShiftSlotDef slot) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(slot.range, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildShiftStaffCell(
    BuildContext context, {
    required RestaurantProvider provider,
    required double width,
    required List<ShiftModel> shifts,
    required bool isTodayColumn,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isTodayColumn
            ? AppTheme.primaryOrange.withValues(alpha: 0.06)
            : Colors.transparent,
        border: isTodayColumn
            ? Border(
                left: BorderSide(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                ),
                right: BorderSide(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                ),
              )
            : null,
      ),
      child: shifts.isEmpty
          ? Center(
              child: Text(
                '—',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: shifts.map((s) {
                final nameLabel = s.openSlot
                    ? '${context.strings.openShiftStoredEmployeeName} (${s.registeredCount}/${s.maxEmployees})'
                    : s.employeeName;
                final timeLabel =
                    '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}'
                    ' - '
                    '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await _showEditShiftDialog(context, s, provider);
                  },
                  onLongPress: () async {
                    final action = await showModalBottomSheet<String>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit, color: Colors.blue),
                              title: Text(context.strings.shiftEditMenuLabel),
                              onTap: () => Navigator.pop(ctx, 'edit'),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text(
                                context.strings.deleteButton,
                                style: const TextStyle(color: Colors.red),
                              ),
                              onTap: () => Navigator.pop(ctx, 'delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (!context.mounted || action == null) return;
                    if (action == 'delete') {
                      await _showDeleteDialog(context, s, provider);
                    }
                  },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: s.openSlot
                            ? AppTheme.statusYellow.withValues(alpha: 0.18)
                            : (isTodayColumn
                                ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                                : AppTheme.primaryOrange.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(8),
                        border: isTodayColumn
                            ? Border.all(
                                color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nameLabel,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      default:
        return 'CN';
    }
  }

  String _getWeekRangeText(DateTime date) {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatDate(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[date.weekday % 7]}, ${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddShiftDialog(
    BuildContext context,
    RestaurantProvider provider,
  ) async {
    final result = await showDialog<List<ShiftModel>>(
      context: context,
      builder: (context) => const AddShiftDialog(),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      var ok = 0;
      for (final shift in result) {
        if (await provider.addShift(shift)) ok++;
      }
      if (!context.mounted) return;
      final total = result.length;
      final allOk = ok == total;
      final partial = ok > 0 && ok < total;
      String message;
      if (allOk) {
        if (total == 1) {
          final one = result.first;
          message = one.openSlot
              ? context.strings.shiftAddedOpenSlot
              : context.strings.shiftAddedFor(one.employeeName);
        } else {
          message = context.strings.shiftBatchAddedSummary(ok, total);
        }
      } else if (partial) {
        message = context.strings.shiftBatchAddedSummary(ok, total);
        final detail = provider.errorMessage?.trim();
        if (detail != null && detail.isNotEmpty) {
          message = '$message\n$detail';
        }
      } else {
        message = context.strings.errorAddingShift;
        final detail = provider.errorMessage?.trim();
        if (detail != null && detail.isNotEmpty) {
          message = '$message\n$detail';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: message.contains('\n') ? 5 : 3),
          backgroundColor: allOk
              ? AppTheme.statusGreen
              : partial
                  ? Colors.orange
                  : AppTheme.statusRed,
        ),
      );
    }
  }

  Future<void> _showEditShiftDialog(
    BuildContext context,
    ShiftModel shift,
    RestaurantProvider provider,
  ) async {
    final result = await showDialog<List<ShiftModel>>(
      context: context,
      builder: (context) => AddShiftDialog(shiftToEdit: shift),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      final success = await provider.updateShift(result.first);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? context.strings.shiftUpdated
                  : context.strings.errorUpdatingShift,
            ),
            backgroundColor: success
                ? AppTheme.statusGreen
                : AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    ShiftModel shift,
    RestaurantProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.confirmDelete),
        content: Text(
          shift.openSlot
              ? context.strings.confirmDeleteOpenShift
              : context.strings.confirmDeleteShift(shift.employeeName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.strings.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteShift(shift.id);
      if (context.mounted) {
        var msg = success
            ? context.strings.shiftDeleted
            : context.strings.errorDeletingShift;
        final detail = provider.errorMessage?.trim();
        if (!success && detail != null && detail.isNotEmpty) {
          msg = '$msg\n$detail';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: Duration(seconds: msg.contains('\n') ? 5 : 3),
            backgroundColor: success
                ? AppTheme.statusGreen
                : AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteAllShifts(
    BuildContext context,
    RestaurantProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả ca làm'),
        content: const Text(
          'Thao tác này sẽ xóa vĩnh viễn TẤT CẢ ca làm trên Firebase.\n'
          'Không thể khôi phục. Bạn chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.strings.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa hết',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    setState(() => _isDeletingAll = true);
    try {
      final count = await provider.deleteAllShifts();
      if (!context.mounted) return;
      final ok = count >= 0;
      final msg = ok
          ? 'Đã xóa $count ca làm.'
          : (provider.errorMessage?.trim().isNotEmpty == true
              ? provider.errorMessage!.trim()
              : 'Xóa thất bại.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? AppTheme.statusGreen : AppTheme.statusRed,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeletingAll = false);
    }
  }
}

class _ShiftSlotDef {
  final String id;
  final String label;
  final String range;
  final int startHour;
  final int startMinute;

  const _ShiftSlotDef({
    required this.id,
    required this.label,
    required this.range,
    required this.startHour,
    required this.startMinute,
  });
}
