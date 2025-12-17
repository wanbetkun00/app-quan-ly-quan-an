import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'enums.dart';

class ShiftModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ShiftStatus status;
  final String? notes;

  ShiftModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = ShiftStatus.scheduled,
    this.notes,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'status': status.name,
      'notes': notes,
    };
  }

  // Convert from Firestore Map
  factory ShiftModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final date = (data['date'] as Timestamp).toDate();
    final startTimeStr = data['startTime'] as String;
    final endTimeStr = data['endTime'] as String;
    
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    
    return ShiftModel(
      id: docId,
      employeeId: data['employeeId'] as String,
      employeeName: data['employeeName'] as String,
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
        (e) => e.name == data['status'],
        orElse: () => ShiftStatus.scheduled,
      ),
      notes: data['notes'] as String?,
    );
  }

  // Get duration in hours
  double get durationHours {
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    return (end - start) / 60.0;
  }

  // Check if shift is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Check if shift is in current week
  bool get isInCurrentWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
           date.isBefore(weekEnd.add(const Duration(days: 1)));
  }
}

