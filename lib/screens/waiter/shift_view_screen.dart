import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shift_model.dart';
import '../../models/enums.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ShiftViewScreen extends StatefulWidget {
  const ShiftViewScreen({super.key});

  @override
  State<ShiftViewScreen> createState() => _ShiftViewScreenState();
}

class _ShiftViewScreenState extends State<ShiftViewScreen> {
  DateTime _currentWeek = DateTime.now();

  List<DateTime> _getWeekDays(DateTime date) {
    // Get Monday of the week
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    
    // Return 7 days from Monday to Sunday
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // If manager, show all shifts; if staff, show only their shifts
    final isManager = authProvider.role == UserRole.manager;
    final employeeId = authProvider.employeeId ?? 'staff';

    final weekDays = _getWeekDays(_currentWeek);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ca làm của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentWeek = _currentWeek.subtract(const Duration(days: 7));
              });
            },
            tooltip: 'Tuần trước',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _currentWeek = DateTime.now();
              });
            },
            tooltip: 'Tuần này',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentWeek = _currentWeek.add(const Duration(days: 7));
              });
            },
            tooltip: 'Tuần sau',
          ),
        ],
      ),
      body: FutureBuilder<List<ShiftModel>>(
        key: ValueKey('${_currentWeek}_$isManager'),
        future: isManager 
            ? _getAllWeekShifts(restaurantProvider)
            : _getWeekShifts(restaurantProvider, employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                    'Lỗi: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            );
          }

          final shifts = snapshot.data ?? [];

          // Group by date - normalize dates for proper comparison
          final groupedShifts = <String, List<ShiftModel>>{};
          for (var shift in shifts) {
            final dateKey = '${shift.date.year}-${shift.date.month}-${shift.date.day}';
            groupedShifts.putIfAbsent(dateKey, () => []).add(shift);
          }
          
          // Debug: print shifts count
          debugPrint('Total shifts: ${shifts.length}');
          debugPrint('Grouped shifts: ${groupedShifts.length}');

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Tuần ${_getWeekNumber(_currentWeek)}/${_currentWeek.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Week view - 7 columns
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: weekDays.map((date) {
                        final dateKey = '${date.year}-${date.month}-${date.day}';
                        final dateShifts = groupedShifts[dateKey] ?? [];
                        return Expanded(
                          child: _buildDayColumn(date, dateShifts),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
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

  Future<List<ShiftModel>> _getWeekShifts(RestaurantProvider provider, String employeeId) async {
    try {
      final weekday = _currentWeek.weekday;
      final weekStart = _currentWeek.subtract(Duration(days: weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      // Normalize dates to start of day for comparison
      final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndNormalized = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      
      final allShifts = await provider.getShiftsForEmployee(employeeId);
      final filteredShifts = allShifts.where((shift) {
        final shiftDate = DateTime(shift.date.year, shift.date.month, shift.date.day);
        // Check if shift date is within the week range (inclusive)
        final isInRange = shiftDate.isAtSameMomentAs(weekStartNormalized) ||
                         (shiftDate.isAfter(weekStartNormalized) && shiftDate.isBefore(weekEndNormalized)) ||
                         shiftDate.isAtSameMomentAs(weekEndNormalized);
        return isInRange;
      }).toList();
      
      debugPrint('Week: ${weekStartNormalized} to ${weekEndNormalized}');
      debugPrint('Total shifts from DB: ${allShifts.length}');
      debugPrint('Filtered shifts: ${filteredShifts.length}');
      
      return filteredShifts;
    } catch (e) {
      debugPrint('Error getting week shifts: $e');
      return [];
    }
  }

  Future<List<ShiftModel>> _getAllWeekShifts(RestaurantProvider provider) async {
    try {
      final weekday = _currentWeek.weekday;
      final weekStart = _currentWeek.subtract(Duration(days: weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      // Normalize dates to start of day for comparison
      final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndNormalized = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      
      // Get all shifts (not filtered by employee)
      final allShifts = await provider.getShifts();
      final filteredShifts = allShifts.where((shift) {
        final shiftDate = DateTime(shift.date.year, shift.date.month, shift.date.day);
        // Check if shift date is within the week range (inclusive)
        final isInRange = shiftDate.isAtSameMomentAs(weekStartNormalized) ||
                         (shiftDate.isAfter(weekStartNormalized) && shiftDate.isBefore(weekEndNormalized)) ||
                         shiftDate.isAtSameMomentAs(weekEndNormalized);
        return isInRange;
      }).toList();
      
      debugPrint('Week: ${weekStartNormalized} to ${weekEndNormalized}');
      debugPrint('Total shifts from DB: ${allShifts.length}');
      debugPrint('Filtered shifts: ${filteredShifts.length}');
      
      return filteredShifts;
    } catch (e) {
      debugPrint('Error getting all week shifts: $e');
      return [];
    }
  }

  Widget _buildDayColumn(DateTime date, List<ShiftModel> shifts) {
    final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
    
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekdayName = weekdays[date.weekday % 7];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primaryOrange.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? AppTheme.primaryOrange : Colors.grey[300]!,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryOrange : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  weekdayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.black87,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Hôm nay',
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
          ),
          // Shifts list
          Expanded(
            child: shifts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Không có ca',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final isManager = authProvider.role == UserRole.manager;
                      return ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: shifts.length,
                        itemBuilder: (context, index) {
                          return _buildShiftCard(shifts[index], isManager);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(ShiftModel shift, bool showEmployeeName) {
    Color statusColor;
    IconData statusIcon;

    switch (shift.status) {
      case ShiftStatus.scheduled:
        statusColor = AppTheme.statusYellow;
        statusIcon = Icons.schedule;
        break;
      case ShiftStatus.completed:
        statusColor = AppTheme.statusGreen;
        statusIcon = Icons.check_circle;
        break;
      case ShiftStatus.cancelled:
        statusColor = AppTheme.statusRed;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showEmployeeName) ...[
            Text(
              shift.employeeName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${shift.durationHours.toStringAsFixed(1)}h',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
          if (shift.notes != null && shift.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              shift.notes!,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

