import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shift_model.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/week_day_horizontal_pager.dart';

class ShiftViewScreen extends StatefulWidget {
  const ShiftViewScreen({super.key});

  @override
  State<ShiftViewScreen> createState() => _ShiftViewScreenState();
}

class _ShiftViewScreenState extends State<ShiftViewScreen> {
  DateTime _currentWeek = DateTime.now();
  late final PageController _dayPageController;
  int _activeDayIndex = 0;

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

  /// Trang ngày mặc định: hôm nay nếu nằm trong tuần đang xem, không thì Thứ Hai (0).
  int _defaultDayPageIndex() {
    final now = DateTime.now();
    final days = _getWeekDays(_currentWeek);
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
      _currentWeek = newWeek;
      _activeDayIndex = _defaultDayPageIndex();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dayPageController.hasClients) {
        _dayPageController.jumpToPage(_activeDayIndex);
      }
    });
  }

  List<DateTime> _getWeekDays(DateTime date) {
    // Get Monday of the week
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));

    // Return 7 days from Monday to Sunday
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  List<ShiftModel> _shiftsInWeekForStaff(
    List<ShiftModel> all,
    String employeeId,
  ) {
    final weekday = _currentWeek.weekday;
    final weekStart = _currentWeek.subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekStartN = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEndN = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

    return all.where((shift) {
      final shiftDate =
          DateTime(shift.date.year, shift.date.month, shift.date.day);
      final inWeek = shiftDate.isAtSameMomentAs(weekStartN) ||
          (shiftDate.isAfter(weekStartN) &&
              shiftDate.isBefore(weekEndN)) ||
          shiftDate.isAtSameMomentAs(weekEndN);
      if (!inWeek) return false;
      if (shift.openSlot) return true;
      if (employeeId.isEmpty) return false;
      return shift.involvesEmployee(employeeId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final employeeId = auth.employeeId ?? '';

    final weekDays = _getWeekDays(_currentWeek);

    return Scaffold(
      backgroundColor: AppTheme.lightGreyBg,
      appBar: AppBar(
        title: Text(
          context.strings.myShiftsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.strings.refresh,
            onPressed: () => restaurantProvider.refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () {
              _setWeekAndSyncDayPage(
                _currentWeek.subtract(const Duration(days: 7)),
              );
            },
            tooltip: context.strings.previousWeek,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.today, size: 24),
              onPressed: () {
                _setWeekAndSyncDayPage(DateTime.now());
              },
              tooltip: context.strings.thisWeek,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: () {
              _setWeekAndSyncDayPage(
                _currentWeek.add(const Duration(days: 7)),
              );
            },
            tooltip: context.strings.nextWeek,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ShiftModel>>(
        key: ValueKey(_currentWeek.millisecondsSinceEpoch),
        stream: restaurantProvider.getShiftsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    '${context.strings.errorLoading} ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            );
          }

          final shifts =
              _shiftsInWeekForStaff(snapshot.data ?? [], employeeId);

          // Group by date - normalize dates for proper comparison
          final groupedShifts = <String, List<ShiftModel>>{};
          for (var shift in shifts) {
            final dateKey =
                '${shift.date.year}-${shift.date.month}-${shift.date.day}';
            groupedShifts.putIfAbsent(dateKey, () => []).add(shift);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryOrange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.strings.weekLabel(
                            _getWeekNumber(_currentWeek),
                            _currentWeek.year,
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreyText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDateRange(weekDays.first, weekDays.last),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                WeekDayStrip(
                  weekDays: weekDays,
                  selectedIndex: _activeDayIndex,
                  pageController: _dayPageController,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _dayPageController,
                    onPageChanged: (i) {
                      setState(() => _activeDayIndex = i);
                    },
                    itemCount: weekDays.length,
                    itemBuilder: (context, index) {
                      final date = weekDays[index];
                      final dateKey =
                          '${date.year}-${date.month}-${date.day}';
                      final dateShifts = groupedShifts[dateKey] ?? [];
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildDayCard(
                          context,
                          date,
                          dateShifts,
                          restaurantProvider,
                          employeeId,
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
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final daysSinceFirstJan = date.difference(firstJan).inDays;
    return ((daysSinceFirstJan + firstJan.weekday) / 7).ceil();
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  Widget _buildDayCard(
    BuildContext context,
    DateTime date,
    List<ShiftModel> shifts,
    RestaurantProvider restaurantProvider,
    String employeeId,
  ) {
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final weekdayName = context.strings.getWeekdayAbbr(date.weekday);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppTheme.primaryOrange : Colors.grey[200]!,
          width: isToday ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppTheme.primaryOrange.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isToday ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: isToday
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.primaryOrange.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isToday ? null : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          weekdayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isToday ? Colors.white : Colors.grey[700],
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              context.strings.today,
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (shifts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${shifts.length} ${context.strings.shifts}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : AppTheme.primaryOrange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Shifts list
          if (shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      context.strings.noShifts,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: shifts.map((shift) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildShiftCard(
                      context,
                      shift,
                      restaurantProvider,
                      employeeId,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _openSlotStaffingColor(ShiftStaffingLevel level) {
    switch (level) {
      case ShiftStaffingLevel.deficit:
        return Colors.red.shade600;
      case ShiftStaffingLevel.almostFull:
        return Colors.amber.shade800;
      case ShiftStaffingLevel.full:
        return Colors.green.shade600;
      case ShiftStaffingLevel.na:
        return AppTheme.primaryOrange;
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

  Widget _buildShiftCard(
    BuildContext context,
    ShiftModel shift,
    RestaurantProvider restaurantProvider,
    String employeeId,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (shift.status) {
      case ShiftStatus.scheduled:
        statusColor = const Color(0xFFFFB800);
        statusIcon = Icons.schedule;
        break;
      case ShiftStatus.completed:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle;
        break;
      case ShiftStatus.cancelled:
        statusColor = const Color(0xFFE53935);
        statusIcon = Icons.cancel;
        break;
    }

    final staffingColor = shift.openSlot
        ? _openSlotStaffingColor(shift.staffingLevel)
        : statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shift.openSlot) ...[
              Row(
                children: [
                  Icon(Icons.groups_2, size: 12, color: AppTheme.darkGreyText),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${context.strings.openShiftStoredEmployeeName} · ${shift.registeredCount}/${shift.maxEmployees}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreyText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: staffingColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _staffingLabel(context, shift),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: staffingColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 1,
                color: statusColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: AppTheme.darkGreyText),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shift.employeeName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 1,
                color: statusColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(statusIcon, size: 16, color: statusColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${shift.durationHours.toStringAsFixed(1)} ${context.strings.hours}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (shift.openSlot &&
                shift.status == ShiftStatus.scheduled) ...[
              const SizedBox(height: 10),
              if (employeeId.isEmpty)
                Text(
                  context.strings.shiftSignupRequiresLinkedAccount,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                )
              else if (shift.isRegistered(employeeId))
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final err =
                          await restaurantProvider.unregisterStaffFromOpenShift(
                        shiftId: shift.id,
                        employeeId: employeeId,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            err ?? context.strings.shiftUnregisterSuccess,
                          ),
                          backgroundColor:
                              err != null ? Colors.red : AppTheme.statusGreen,
                        ),
                      );
                    },
                    child: Text(context.strings.unregisterFromShift),
                  ),
                )
              else if (shift.isFull)
                Text(
                  context.strings.shiftStaffFull,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final err =
                          await restaurantProvider.registerStaffForOpenShift(
                        shiftId: shift.id,
                        employeeId: employeeId,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            err ?? context.strings.shiftRegisterSuccess,
                          ),
                          backgroundColor:
                              err != null ? Colors.red : AppTheme.statusGreen,
                        ),
                      );
                    },
                    child: Text(context.strings.registerForShift),
                  ),
                ),
            ],
            if (shift.notes != null && shift.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 10, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        shift.notes!,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
