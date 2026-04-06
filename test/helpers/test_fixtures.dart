import 'package:do_an_mon_quanlyquanan/models/employee_model.dart';
import 'package:do_an_mon_quanlyquanan/models/enums.dart';
import 'package:do_an_mon_quanlyquanan/models/menu_item.dart';
import 'package:do_an_mon_quanlyquanan/models/order_item.dart';
import 'package:do_an_mon_quanlyquanan/models/order_model.dart';
import 'package:do_an_mon_quanlyquanan/models/report_model.dart';
import 'package:do_an_mon_quanlyquanan/models/table_model.dart';

class TestFixtures {
  static MenuItem menuItem({
    int id = 1,
    String name = 'Pho',
    double price = 50000,
    MenuCategory category = MenuCategory.food,
  }) {
    return MenuItem(id: id, name: name, price: price, category: category);
  }

  static OrderItem orderItem({
    MenuItem? item,
    int quantity = 1,
  }) {
    return OrderItem(menuItem: item ?? menuItem(), quantity: quantity);
  }

  static OrderModel order({
    int id = 1001,
    int tableId = 1,
    List<OrderItem>? items,
    OrderStatus status = OrderStatus.pending,
    String? employeeId = 'emp-1',
  }) {
    return OrderModel(
      id: id,
      tableId: tableId,
      timestamp: DateTime(2026, 1, 1, 10),
      items: items ?? [orderItem()],
      status: status,
      employeeId: employeeId,
    );
  }

  static TableModel table({
    int id = 1,
    String name = 'Ban 1',
    TableStatus status = TableStatus.available,
    int? currentOrderId,
  }) {
    return TableModel(
      id: id,
      name: name,
      status: status,
      currentOrderId: currentOrderId,
    );
  }

  static EmployeeModel employee({
    String id = 'emp-1',
    String username = 'manager',
    String name = 'Manager',
    String password = '1234',
    UserRole role = UserRole.manager,
    bool isActive = true,
  }) {
    return EmployeeModel(
      id: id,
      username: username,
      name: name,
      password: password,
      role: role,
      isActive: isActive,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  static ReportModel report({
    ReportType type = ReportType.weekly,
    DateTime? startDate,
    DateTime? endDate,
    double totalRevenue = 100000,
    int totalOrders = 2,
    Map<String, int>? itemSales,
    Map<String, double>? itemRevenue,
  }) {
    return ReportModel(
      id: 'r1',
      type: type,
      startDate: startDate ?? DateTime(2026, 4, 6),
      endDate: endDate ?? DateTime(2026, 4, 12, 23, 59, 59),
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      itemSales: itemSales ?? const {'1': 2},
      itemRevenue: itemRevenue ?? const {'1': 100000},
      createdAt: DateTime(2026, 4, 12),
    );
  }
}
