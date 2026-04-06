import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mon_quanlyquanan/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportModel', () {
    test('periodLabel formats weekly period', () {
      final report = ReportModel(
        id: 'r1',
        type: ReportType.weekly,
        startDate: DateTime(2026, 4, 6),
        endDate: DateTime(2026, 4, 12, 23, 59, 59),
        totalRevenue: 100000,
        totalOrders: 2,
        itemSales: const {'1': 2},
        itemRevenue: const {'1': 100000},
      );

      expect(report.periodLabel, contains('Tuần'));
      expect(report.periodLabel, contains('/2026'));
    });

    test('periodLabel formats monthly and yearly periods', () {
      final monthly = ReportModel(
        id: 'r2',
        type: ReportType.monthly,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30, 23, 59, 59),
        totalRevenue: 0,
        totalOrders: 0,
        itemSales: const {},
        itemRevenue: const {},
      );
      final yearly = ReportModel(
        id: 'r3',
        type: ReportType.yearly,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31, 23, 59, 59),
        totalRevenue: 0,
        totalOrders: 0,
        itemSales: const {},
        itemRevenue: const {},
      );

      expect(monthly.periodLabel, '4/2026');
      expect(yearly.periodLabel, 'Năm 2026');
    });

    test('fromFirestore parses numeric and map fields correctly', () {
      final data = <String, dynamic>{
        'type': 'monthly',
        'startDate': Timestamp.fromDate(DateTime(2026, 4, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 4, 30, 23, 59, 59)),
        'totalRevenue': 250000,
        'totalOrders': 5,
        'itemSales': {'1': 3, '2': 2},
        'itemRevenue': {'1': 150000, '2': 100000},
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 30)),
      };

      final report = ReportModel.fromFirestore('doc-report-1', data);

      expect(report.id, 'doc-report-1');
      expect(report.type, ReportType.monthly);
      expect(report.totalRevenue, 250000);
      expect(report.totalOrders, 5);
      expect(report.itemSales['1'], 3);
      expect(report.itemRevenue['2'], 100000);
    });
  });
}
