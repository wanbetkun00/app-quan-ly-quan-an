import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType { weekly, monthly, yearly }

class ReportModel {
  final String id;
  final ReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final int totalOrders;
  final Map<String, int> itemSales; // menuItemId -> quantity sold
  final Map<String, double> itemRevenue; // menuItemId -> revenue
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalOrders,
    required this.itemSales,
    required this.itemRevenue,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'itemSales': itemSales.map((k, v) => MapEntry(k.toString(), v)),
      'itemRevenue': itemRevenue.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert from Firestore Map
  factory ReportModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return ReportModel(
      id: docId,
      type: ReportType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReportType.weekly,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      totalOrders: data['totalOrders'] as int,
      itemSales: (data['itemSales'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      itemRevenue: (data['itemRevenue'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get periodLabel {
    switch (type) {
      case ReportType.weekly:
        return 'Tuần ${_getWeekNumber(startDate)}/${startDate.year}';
      case ReportType.monthly:
        return '${startDate.month}/${startDate.year}';
      case ReportType.yearly:
        return 'Năm ${startDate.year}';
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final daysSinceFirstJan = date.difference(firstJan).inDays;
    return ((daysSinceFirstJan + firstJan.weekday) / 7).ceil();
  }
}

