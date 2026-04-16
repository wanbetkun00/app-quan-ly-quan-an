import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/restaurant_provider.dart';
import 'firestore_service.dart';

// ============================================================================
// CLASS 1: GIAO TIẾP VỚI API GEMINI VÀ XỬ LÝ FALLBACK (DỰ PHÒNG LỖI)
// ============================================================================
class GeminiManagerChatService {
  String? _apiKey() {
    final v = dotenv.env['GEMINI_API_KEY']?.trim();
    if (v != null && v.isNotEmpty) return v;
    for (final e in dotenv.env.entries) {
      if (e.key.trim() == 'GEMINI_API_KEY') {
        final val = e.value.trim();
        if (val.isNotEmpty) return val;
      }
    }
    return null;
  }

  Future<String> generateReply({
    required String systemInstruction,
    required String restaurantContext,
    required List<ManagerChatMessage> historyIncludingLatestUser,
  }) async {
    final key = _apiKey();
    if (key == null || key.isEmpty) {
      throw StateError(
        'Thiếu GEMINI_API_KEY trong file .env',
      );
    }

    final contents = <Map<String, dynamic>>[];

    if (restaurantContext.trim().isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {
            'text':
                '[DỮ LIỆU HỆ THỐNG — không phải yêu cầu của người dùng]\n$restaurantContext',
          },
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                'Đã nhận dữ liệu nhà hàng. Tôi sẽ dùng để gợi ý combo, ca làm, món mới khi được hỏi.',
          },
        ],
      });
    }

    for (final m in historyIncludingLatestUser) {
      contents.add({
        'role': m.role,
        'parts': [
          {'text': m.text},
        ],
      });
    }

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    });

    // Fallback: thử lần lượt các model cho đến khi thành công
    final models = <String>[
      'gemini-2.5-pro',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
    ];

    Object? lastError;

    for (final modelName in models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key',
        );

        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 25));

        if (res.statusCode != 200) {
          throw Exception(
            'HTTP ${res.statusCode}: ${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
          );
        }

        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'];
        if (candidates is! List || candidates.isEmpty) {
          final feedback = decoded['promptFeedback'];
          throw Exception('Không có phản hồi. $feedback');
        }

        final first = candidates.first as Map<String, dynamic>;
        final content = first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw Exception('Phản hồi rỗng.');
        }

        final text =
            (parts.first as Map<String, dynamic>)['text'] as String?;
        if (text == null || text.isEmpty) {
          throw Exception('Nội dung phản hồi trống.');
        }

        return text.trim();
      } catch (e) {
        lastError = e;
        debugPrint('Gemini [$modelName] lỗi: $e — thử model tiếp…');
      }
    }

    throw Exception(
      'Tất cả model Gemini đều lỗi. Chi tiết: $lastError',
    );
  }
}

// ============================================================================
// CLASS 2: XÂY DỰNG NGỮ CẢNH (CONTEXT) TỪ FIREBASE CHO AI HIỂU
// ============================================================================
class ManagerAiContextService {
  final FirestoreService _firestore = FirestoreService();

  static const _dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  Future<String> buildContext(RestaurantProvider provider) async {
    final menu = provider.menu;
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon
    final df = DateFormat('dd/MM/yyyy');
    final todayStart = DateTime(now.year, now.month, now.day);

    // ── Mốc thời gian ──
    final startOfThisWeek = todayStart.subtract(Duration(days: weekday - 1));
    final endOfThisWeek = DateTime(
      startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day,
      23, 59, 59,
    ).add(const Duration(days: 6));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = DateTime(
      startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day,
      23, 59, 59,
    ).add(const Duration(days: 6));

    // ── Lấy đơn hàng 2 tuần ──
    List<OrderModel> lastWeekOrders = [];
    List<OrderModel> thisWeekOrders = [];
    if (menu.isNotEmpty) {
      lastWeekOrders = await _firestore.getPaidCompletedOrdersInRange(
        startOfLastWeek, endOfLastWeek, menu,
      );
      thisWeekOrders = await _firestore.getPaidCompletedOrdersInRange(
        startOfThisWeek, endOfThisWeek, menu,
      );
    }

    // ── 1) Doanh thu TỪNG NGÀY tuần trước ──
    final lastWeekDaily = _revenueByDay(lastWeekOrders, startOfLastWeek);
    final lastWeekDailyStr = lastWeekDaily.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}đ')
        .join(', ');

    // ── 2) Doanh thu TỪNG NGÀY tuần này (đến hôm nay) ──
    final thisWeekDaily = _revenueByDay(thisWeekOrders, startOfThisWeek);
    final thisWeekDailyStr = thisWeekDaily.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}đ')
        .join(', ');

    // ── Tổng doanh thu 2 tuần ──
    final lastWeekRevenue = lastWeekOrders.fold<double>(0, (s, o) => s + o.total);
    final thisWeekRevenue = thisWeekOrders.fold<double>(0, (s, o) => s + o.total);

    // ── 3) Xếp hạng TẤT CẢ món (bán chạy → bán kém) tuần trước ──
    final itemCounts = _countItems(lastWeekOrders);
    final sortedDesc = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedDesc.take(5)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    final bottom5 = sortedDesc.reversed.take(5)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    // Món trong menu nhưng KHÔNG bán được tuần trước
    final soldNames = itemCounts.keys.toSet();
    final unsold = menu
        .where((m) => !soldNames.contains(m.name))
        .map((m) => m.name)
        .take(10)
        .join(', ');

    // ── 4) Giờ cao điểm (theo số đơn) tuần trước ──
    final hourCounts = <int, int>{};
    for (final o in lastWeekOrders) {
      final h = o.timestamp.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    final hourSorted = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = hourSorted.take(5)
        .map((e) => '${e.key}h: ${e.value} đơn')
        .join(', ');

    // ── 5) So sánh tuần này vs tuần trước ──
    final diffRevenue = thisWeekRevenue - lastWeekRevenue;
    final diffOrders = thisWeekOrders.length - lastWeekOrders.length;
    final pctChange = lastWeekRevenue > 0
        ? (diffRevenue / lastWeekRevenue * 100).toStringAsFixed(1)
        : 'N/A';

    // ── Menu, bàn, nhân viên, ca ──
    final menuSample = menu.take(40)
        .map((m) => '${m.name} [${m.category.name}] ${m.price.toStringAsFixed(0)}đ')
        .join('; ');

    final empLines = provider.employees
        .map((e) => '${e['name']} (id: ${e['id']})')
        .join(', ');

    final shifts = await _firestore.getShiftsInRange(
      startOfThisWeek.subtract(const Duration(days: 1)),
      startOfThisWeek.add(const Duration(days: 20)),
    );
    final shiftLines = shifts.take(25).map((s) {
      final d = DateFormat('dd/MM').format(s.date);
      final staff = s.openSlot
          ? 'Ca mở (${s.registeredCount}/${s.maxEmployees} đăng ký)'
          : s.employeeName;
      return '$d ${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}'
          '-${s.endTime.hour}:${s.endTime.minute.toString().padLeft(2, '0')} $staff';
    }).join('\n');

    return '''
DỮ LIỆU NHÀ HÀNG (tự động cào từ Firebase lúc ${DateFormat('HH:mm dd/MM').format(now)})

═══ DOANH THU TUẦN TRƯỚC (${df.format(startOfLastWeek)} → ${df.format(endOfLastWeek)}) ═══
Tổng: ${lastWeekRevenue.toStringAsFixed(0)}đ | ${lastWeekOrders.length} đơn
Theo ngày: $lastWeekDailyStr

═══ DOANH THU TUẦN NÀY (${df.format(startOfThisWeek)} → hôm nay ${df.format(todayStart)}) ═══
Tổng tạm: ${thisWeekRevenue.toStringAsFixed(0)}đ | ${thisWeekOrders.length} đơn
Theo ngày: $thisWeekDailyStr

═══ SO SÁNH TUẦN NÀY vs TUẦN TRƯỚC ═══
Chênh lệch doanh thu: ${diffRevenue >= 0 ? '+' : ''}${diffRevenue.toStringAsFixed(0)}đ ($pctChange%)
Chênh lệch đơn: ${diffOrders >= 0 ? '+' : ''}$diffOrders đơn

═══ MÓN BÁN CHẠY NHẤT (tuần trước, theo số lượng) ═══
${top5.isEmpty ? 'Chưa có dữ liệu' : top5}

═══ MÓN BÁN KÉM NHẤT (tuần trước) ═══
${bottom5.isEmpty ? 'Chưa có' : bottom5}
${unsold.isNotEmpty ? 'Không bán được món nào: $unsold' : ''}

═══ GIỜ CAO ĐIỂM (tuần trước, theo số đơn) ═══
${peakHours.isEmpty ? 'Chưa có' : peakHours}

═══ MENU HIỆN TẠI ═══
${menu.isEmpty ? 'Trống' : menuSample}
Tổng: ${menu.length} (ăn: ${provider.foodItems}, uống: ${provider.drinkItems})

═══ BÀN ═══
${provider.totalTables} bàn (trống: ${provider.availableTables}, có khách: ${provider.occupiedTables}, chờ thanh toán: ${provider.paymentPendingTables})

═══ NHÂN VIÊN ═══
${empLines.isEmpty ? 'Chưa có' : empLines}

═══ CA LÀM (tối đa 25 dòng) ═══
${shiftLines.isEmpty ? 'Chưa có' : shiftLines}
''';
  }

  /// Doanh thu theo từng ngày trong tuần (T2→CN)
  Map<String, double> _revenueByDay(List<OrderModel> orders, DateTime weekStart) {
    final result = <String, double>{};
    for (var i = 0; i < 7; i++) {
      result[_dayNames[i]] = 0;
    }
    for (final o in orders) {
      final dayIdx = o.timestamp.weekday - 1; // 0=Mon
      if (dayIdx >= 0 && dayIdx < 7) {
        result[_dayNames[dayIdx]] = (result[_dayNames[dayIdx]] ?? 0) + o.total;
      }
    }
    return result;
  }

  /// Đếm số lượng bán của từng món
  Map<String, int> _countItems(List<OrderModel> orders) {
    final counts = <String, int>{};
    for (final o in orders) {
      for (final line in o.items) {
        counts[line.menuItem.name] = (counts[line.menuItem.name] ?? 0) + line.quantity;
      }
    }
    return counts;
  }
}
