import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'enums.dart';

/// Ca mở đăng ký: `employeeId` lưu [openSlotEmployeeId], nhân viên đăng ký trong `registeredEmployeeIds`.
class ShiftModel {
  static const String openSlotEmployeeId = '__open__';

  final String id;
  /// Với ca mở: [openSlotEmployeeId]. Với ca gán 1 người (legacy): id nhân viên.
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ShiftStatus status;
  final String? notes;

  /// `true`: ca do quản lý tạo, staff đăng ký; `false`: ca gán cố định một nhân viên (dữ liệu cũ).
  final bool openSlot;

  /// Số người tối đa (chỉ dùng khi [openSlot]).
  final int maxEmployees;

  /// Danh sách id nhân viên đã đăng ký (chỉ dùng khi [openSlot]).
  final List<String> registeredEmployeeIds;

  ShiftModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = ShiftStatus.scheduled,
    this.notes,
    this.openSlot = false,
    this.maxEmployees = 1,
    List<String>? registeredEmployeeIds,
  }) : registeredEmployeeIds = List<String>.from(registeredEmployeeIds ?? const []);

  int get registeredCount => registeredEmployeeIds.length;

  bool get isFull => openSlot && registeredCount >= maxEmployees;

  /// 🔴 thiếu nhiều, 🟡 còn 1 chỗ, 🟢 đủ slot.
  ShiftStaffingLevel get staffingLevel {
    if (!openSlot) return ShiftStaffingLevel.na;
    if (registeredCount >= maxEmployees) return ShiftStaffingLevel.full;
    if (maxEmployees - registeredCount == 1) {
      return ShiftStaffingLevel.almostFull;
    }
    return ShiftStaffingLevel.deficit;
  }

  bool isRegistered(String employeeId) =>
      employeeId.isNotEmpty && registeredEmployeeIds.contains(employeeId);

  /// Nhân viên có tham gia ca này (đăng ký hoặc được gán legacy).
  bool involvesEmployee(String employeeId) {
    if (employeeId.isEmpty) return false;
    if (registeredEmployeeIds.contains(employeeId)) return true;
    if (!openSlot &&
        employeeId.isNotEmpty &&
        this.employeeId.isNotEmpty &&
        this.employeeId != openSlotEmployeeId &&
        this.employeeId == employeeId) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'startTime':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'status': status.name,
      'notes': notes,
      'openSlot': openSlot,
      'maxEmployees': maxEmployees,
      'registeredEmployeeIds': registeredEmployeeIds,
    };
  }

  factory ShiftModel.fromFirestore(String docId, Map<String, dynamic> data) {
    try {
      DateTime date;
      if (data['date'] is Timestamp) {
        date = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is DateTime) {
        date = data['date'] as DateTime;
      } else {
        throw Exception('Invalid date format in Firestore data');
      }

      final startTimeStr = data['startTime'] as String? ?? '08:00';
      final endTimeStr = data['endTime'] as String? ?? '17:00';

      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');

      if (startParts.length != 2 || endParts.length != 2) {
        throw Exception(
          'Invalid time format: startTime=$startTimeStr, endTime=$endTimeStr',
        );
      }

      final empId = data['employeeId'] as String? ?? '';
      final openSlot =
          data['openSlot'] == true || empId == ShiftModel.openSlotEmployeeId;

      var maxEmployees = (data['maxEmployees'] as num?)?.toInt() ?? 1;
      if (maxEmployees < 1) maxEmployees = 1;

      List<String> registeredEmployeeIds = [];
      final rawList = data['registeredEmployeeIds'];
      if (rawList is List) {
        registeredEmployeeIds = rawList.map((e) => e.toString()).toList();
      }

      if (!openSlot &&
          registeredEmployeeIds.isEmpty &&
          empId.isNotEmpty &&
          empId != ShiftModel.openSlotEmployeeId) {
        registeredEmployeeIds = [empId];
      }

      return ShiftModel(
        id: docId,
        employeeId: empId,
        employeeName: data['employeeName'] as String? ?? '',
        date: date,
        startTime: TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        ),
        endTime: TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        ),
        status: ShiftStatus.values.firstWhere(
          (e) => e.name == (data['status'] as String? ?? 'scheduled'),
          orElse: () => ShiftStatus.scheduled,
        ),
        notes: data['notes'] as String?,
        openSlot: openSlot,
        maxEmployees: openSlot ? maxEmployees : 1,
        registeredEmployeeIds: openSlot
            ? registeredEmployeeIds
            : registeredEmployeeIds,
      );
    } catch (e) {
      debugPrint('Error parsing shift from Firestore: $e');
      debugPrint('Doc ID: $docId');
      debugPrint('Data: $data');
      rethrow;
    }
  }

  ShiftModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ShiftStatus? status,
    String? notes,
    bool? openSlot,
    int? maxEmployees,
    List<String>? registeredEmployeeIds,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      openSlot: openSlot ?? this.openSlot,
      maxEmployees: maxEmployees ?? this.maxEmployees,
      registeredEmployeeIds:
          registeredEmployeeIds ?? List<String>.from(this.registeredEmployeeIds),
    );
  }

  double get durationHours {
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    return (end - start) / 60.0;
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isInCurrentWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        date.isBefore(weekEnd.add(const Duration(days: 1)));
  }
}

enum ShiftStaffingLevel {
  /// Ca gán tay / không áp dụng chỉ báo.
  na,
  /// Đã đủ người đăng ký.
  full,
  /// Còn đúng 1 chỗ.
  almostFull,
  /// Thiếu nhiều hơn 1 người.
  deficit,
}
