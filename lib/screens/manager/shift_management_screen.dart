import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shift_model.dart';
import '../../models/enums.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.shiftManagementTitle),
        actions: [
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
                    setState(() {
                      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedWeek,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedWeek = picked;
                      });
                    }
                  },
                  child: Text(
                    _getWeekRangeText(_selectedWeek),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
                    });
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
                  child: DropdownButton<String>(
                    value: _selectedEmployeeId,
                    isExpanded: true,
                    hint: Text(context.strings.allEmployees),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(context.strings.allEmployees),
                      ),
                      ...provider.employees.map((emp) {
                        return DropdownMenuItem<String>(
                          value: emp['id'],
                          child: Text(emp['name'] ?? ''),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                      });
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
                    child: Text('${context.strings.errorLoading} ${snapshot.error}'),
                  );
                }

                final allShifts = snapshot.data ?? [];
                
                // Filter by week
                final weekStart = _getWeekStart(_selectedWeek);
                final weekEnd = weekStart.add(const Duration(days: 6));
                final weekShifts = allShifts.where((shift) {
                  final shiftDate = DateTime(
                    shift.date.year,
                    shift.date.month,
                    shift.date.day,
                  );
                  return shiftDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                         shiftDate.isBefore(weekEnd.add(const Duration(days: 1)));
                }).toList();

                // Filter by employee if selected
                final filteredShifts = _selectedEmployeeId == null
                    ? weekShifts
                    : weekShifts.where((shift) => shift.employeeId == _selectedEmployeeId).toList();

                if (filteredShifts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          context.strings.noShiftsThisWeek,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Group by date
                final groupedShifts = <DateTime, List<ShiftModel>>{};
                for (var shift in filteredShifts) {
                  final date = DateTime(shift.date.year, shift.date.month, shift.date.day);
                  groupedShifts.putIfAbsent(date, () => []).add(shift);
                }

                final sortedDates = groupedShifts.keys.toList()..sort();

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.refreshShifts();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final shifts = groupedShifts[date]!;
                      
                      return _buildDateSection(date, shifts, provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(DateTime date, List<ShiftModel> shifts, RestaurantProvider provider) {
    final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryOrange.withValues(alpha: 0.1) : Colors.grey[100],
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...shifts.map((shift) => _buildShiftTile(context, shift, provider)),
        ],
      ),
    );
  }

  Widget _buildShiftTile(BuildContext context, ShiftModel shift, RestaurantProvider provider) {
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

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(statusIcon, color: statusColor),
      ),
      title: Text(
        shift.employeeName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Text(
                '(${shift.durationHours.toStringAsFixed(1)}h)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (shift.notes != null && shift.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              shift.notes!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                await _showEditShiftDialog(context, shift, provider);
              } else if (value == 'delete') {
                await _showDeleteDialog(context, shift, provider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(context.strings.editButton),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(context.strings.deleteButton),
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

  Future<void> _showAddShiftDialog(BuildContext context, RestaurantProvider provider) async {
    final result = await showDialog<ShiftModel>(
      context: context,
      builder: (context) => const AddShiftDialog(),
    );
    if (result != null && context.mounted) {
      final success = await provider.addShift(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? context.strings.shiftAddedFor(result.employeeName)
                : context.strings.errorAddingShift),
            backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _showEditShiftDialog(BuildContext context, ShiftModel shift, RestaurantProvider provider) async {
    final result = await showDialog<ShiftModel>(
      context: context,
      builder: (context) => AddShiftDialog(shiftToEdit: shift),
    );
    if (result != null && context.mounted) {
      final success = await provider.updateShift(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? context.strings.shiftUpdated
                : context.strings.errorUpdatingShift),
            backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, ShiftModel shift, RestaurantProvider provider) async {
      final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.confirmDelete),
        content: Text(context.strings.confirmDeleteShift(shift.employeeName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.strings.deleteButton, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteShift(shift.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? context.strings.shiftDeleted
                : context.strings.errorDeletingShift),
            backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
          ),
        );
      }
    }
  }
}

