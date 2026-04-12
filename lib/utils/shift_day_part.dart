import 'package:flutter/material.dart';

/// Phân loại khung giờ chuẩn (khớp đúng 3 ca Sáng / Chiều / Tối).
enum ShiftDayPart { morning, afternoon, evening, custom }

bool _sameTime(TimeOfDay a, TimeOfDay b) =>
    a.hour == b.hour && a.minute == b.minute;

/// Trả về [morning|afternoon|evening] nếu khớp đúng một trong ba khung mặc định, ngược lại [custom].
ShiftDayPart classifyShiftDayPart(TimeOfDay start, TimeOfDay end) {
  const morningStart = TimeOfDay(hour: 7, minute: 0);
  const morningEnd = TimeOfDay(hour: 12, minute: 0);
  const afternoonStart = TimeOfDay(hour: 13, minute: 0);
  const afternoonEnd = TimeOfDay(hour: 18, minute: 0);
  const eveningStart = TimeOfDay(hour: 18, minute: 0);
  const eveningEnd = TimeOfDay(hour: 23, minute: 0);

  if (_sameTime(start, morningStart) && _sameTime(end, morningEnd)) {
    return ShiftDayPart.morning;
  }
  if (_sameTime(start, afternoonStart) && _sameTime(end, afternoonEnd)) {
    return ShiftDayPart.afternoon;
  }
  if (_sameTime(start, eveningStart) && _sameTime(end, eveningEnd)) {
    return ShiftDayPart.evening;
  }
  return ShiftDayPart.custom;
}

String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Hai khoảng [start1–end1] và [start2–end2] có giao nhau (cùng ngày).
bool shiftTimeRangesOverlap(
  TimeOfDay start1,
  TimeOfDay end1,
  TimeOfDay start2,
  TimeOfDay end2,
) {
  final s1 = start1.hour * 60 + start1.minute;
  final e1 = end1.hour * 60 + end1.minute;
  final s2 = start2.hour * 60 + start2.minute;
  final e2 = end2.hour * 60 + end2.minute;
  return s1 < e2 && s2 < e1;
}
