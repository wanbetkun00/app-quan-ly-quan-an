import 'package:flutter/material.dart';
import '../models/models.dart';
import '../constants/dummy_data.dart';
import '../theme/app_theme.dart';

class RestaurantProvider extends ChangeNotifier {
  List<TableModel> tables = dummyTables;
  List<MenuItem> menu = dummyMenu;
  List<OrderModel> activeOrders = [];
  int _orderIdCounter = 1;

  // Waiter: Get table color based on status
  Color getTableColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppTheme.statusGreen;
      case TableStatus.occupied:
        return AppTheme.statusRed;
      case TableStatus.paymentPending:
        return AppTheme.statusYellow;
    }
  }

  // Waiter: Create a new order
  void placeOrder(int tableId, List<OrderItem> items) {
    if (items.isEmpty) return;

    final newOrder = OrderModel(
      id: _orderIdCounter++,
      tableId: tableId,
      timestamp: DateTime.now(),
      items: items,
    );
    activeOrders.add(newOrder);

    // Update table status appropriately
    final tableIndex = tables.indexWhere((t) => t.id == tableId);
    tables[tableIndex].status = TableStatus.occupied;
    tables[tableIndex].currentOrderId = newOrder.id;

    notifyListeners();
  }

  // Kitchen: Advance order status
  void advanceOrderStatus(int orderId) {
    final orderIndex = activeOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return;

    OrderModel order = activeOrders[orderIndex];

    if (order.status == OrderStatus.pending) {
      order.status = OrderStatus.cooking;
    } else if (order.status == OrderStatus.cooking) {
      order.status = OrderStatus.readyToServe;
    } else if (order.status == OrderStatus.readyToServe) {
      order.status = OrderStatus.completed;
      // Make table ready for payment
      final tableIndex = tables.indexWhere((t) => t.id == order.tableId);
      tables[tableIndex].status = TableStatus.paymentPending;
      // In a real app, you might move completed orders to history here
    }
    notifyListeners();
  }

  // Manager Stats (Simple Demo)
  double get dailyRevenue => activeOrders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0, (sum, o) => sum + o.total);
}

