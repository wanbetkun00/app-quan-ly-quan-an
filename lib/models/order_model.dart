import 'enums.dart';
import 'order_item.dart';

class OrderModel {
  final int id;
  final int tableId;
  final DateTime timestamp;
  List<OrderItem> items;
  OrderStatus status;
  final String? employeeId;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.timestamp,
    required this.items,
    this.status = OrderStatus.pending,
    this.employeeId,
  });

  double get total =>
      items.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));
}
