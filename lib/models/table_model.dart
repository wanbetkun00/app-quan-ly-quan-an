import 'enums.dart';

class TableModel {
  final int id;
  final String name;
  TableStatus status;
  int? currentOrderId;

  TableModel({
    required this.id,
    required this.name,
    this.status = TableStatus.available,
    this.currentOrderId,
  });
}
