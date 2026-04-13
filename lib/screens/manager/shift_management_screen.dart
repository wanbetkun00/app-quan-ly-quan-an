import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shift_model.dart';
import '../../models/employee_model.dart';
import '../../models/enums.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_shift_dialog.dart';
import '../../widgets/week_day_horizontal_pager.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  DateTime _selectedWeek = DateTime.now();
  String? _selectedEmployeeId;
  late final PageController _dayPageController;
  int _activeDayIndex = 0;
  bool _isDeletingAll = false;

  @override
  void initState() {
    super.initState();
    _activeDayIndex = _defaultDayPageIndex();
    _dayPageController = PageController(initialPage: _activeDayIndex);
  }

  @override
  void dispose() {
    _dayPageController.dispose();
    super.dispose();
  }

  List<DateTime> _weekDaysForSelected() {
    final m = _getWeekStart(_selectedWeek);
    return List.generate(
      7,
      (i) => DateTime(m.year, m.month, m.day).add(Duration(days: i)),
    );
  }

  int _defaultDayPageIndex() {
    final now = DateTime.now();
    final days = _weekDaysForSelected();
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return i;
      }
    }
    return 0;
  }

  void _setWeekAndSyncDayPage(DateTime newWeek) {
    setState(() {
      _selectedWeek = newWeek;
      _activeDayIndex = _defaultDayPageIndex();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dayPageController.hasClients) {
        _dayPageController.jumpToPage(_activeDayIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.shiftManagementTitle),
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

                final groupedShifts = <DateTime, List<ShiftModel>>{};
                for (var shift in filteredShifts) {
                  final date = DateTime(
                    shift.date.year,
                    shift.date.month,
                    shift.date.day,
                  );
                  groupedShifts.putIfAbsent(date, () => []).add(shift);
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WeekDayStrip(
                        weekDays: weekDays,
                        selectedIndex: _activeDayIndex,
                        pageController: _dayPageController,
                        onSelected: (i) {
                          if (!mounted) return;
                          setState(() => _activeDayIndex = i);
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final safeIndex = _activeDayIndex.clamp(
                              0,
                              weekDays.length - 1,
                            );
                            final date = weekDays[safeIndex];
                            final shifts = groupedShifts[date] ?? [];
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDateSection(
                                date,
                                shifts,
                                provider,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(
    DateTime date,
    List<ShiftModel> shifts,
    RestaurantProvider provider,
  ) {
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isToday ? AppTheme.primaryOrange : Colors.black87,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.strings.today,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${shifts.length} ${context.strings.shifts}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          if (shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Center(
                child: Text(
                  context.strings.noShifts,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ),
            )
          else
            ...shifts.asMap().entries.map((entry) {
              final i = entry.key;
              final shift = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0) const Divider(height: 1),
                  _buildShiftTile(context, shift, provider),
                ],
              );
            }),
        ],
      ),
    );
  }

  Color _staffingDotColor(ShiftStaffingLevel level) {
    switch (level) {
      case ShiftStaffingLevel.deficit:
        return Colors.red.shade600;
      case ShiftStaffingLevel.almostFull:
        return Colors.amber.shade700;
      case ShiftStaffingLevel.full:
        return Colors.green.shade600;
      case ShiftStaffingLevel.na:
        return Colors.grey;
    }
  }

  String _staffingLabel(BuildContext context, ShiftModel shift) {
    final s = context.strings;
    switch (shift.staffingLevel) {
      case ShiftStaffingLevel.full:
        return s.staffingFullLabel;
      case ShiftStaffingLevel.almostFull:
        return s.staffingAlmostFull;
      case ShiftStaffingLevel.deficit:
        return s.staffingDeficit;
      case ShiftStaffingLevel.na:
        return '';
    }
  }

  Widget _buildShiftTile(
    BuildContext context,
    ShiftModel shift,
    RestaurantProvider provider,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (shift.status) {
      case ShiftStatus.scheduled:
        statusColor = AppTheme.statusYellow;
        statusText = context.strings.shiftScheduled;
        statusIcon = Icons.schedule;
        break;
      case ShiftStatus.completed:
        statusColor = AppTheme.statusGreen;
        statusText = context.strings.shiftCompleted;
        statusIcon = Icons.check_circle;
        break;
      case ShiftStatus.cancelled:
        statusColor = AppTheme.statusRed;
        statusText = context.strings.shiftCancelled;
        statusIcon = Icons.cancel;
        break;
    }

    final openStaffingColor = shift.openSlot
        ? _staffingDotColor(shift.staffingLevel)
        : statusColor;
    final openStaffingIcon = shift.openSlot ? Icons.groups_2 : statusIcon;

    final menuStrings = AppStrings(
      Provider.of<LanguageProvider>(context, listen: false).language,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (shift.openSlot ? openStaffingColor : statusColor)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              openStaffingIcon,
              color: shift.openSlot ? openStaffingColor : statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        shift.openSlot
                            ? '${context.strings.openShiftStoredEmployeeName} · ${shift.registeredCount}/${shift.maxEmployees}'
                            : shift.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_formatTime(shift.startTime)} – ${_formatTime(shift.endTime)} (${shift.durationHours.toStringAsFixed(1)}h)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (shift.openSlot) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: openStaffingColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _staffingLabel(context, shift),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: openStaffingColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (shift.notes != null && shift.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    shift.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: menuStrings.shiftActionMenuTooltip,
            icon: const Icon(Icons.more_vert),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onSelected: (value) async {
              if (value == 'edit') {
                await _showEditShiftDialog(context, shift, provider);
              } else if (value == 'delete') {
                await _showDeleteDialog(context, shift, provider);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(menuStrings.shiftEditMenuLabel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      menuStrings.shiftDeleteMenuLabel,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
