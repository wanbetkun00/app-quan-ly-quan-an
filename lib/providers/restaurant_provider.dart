import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/report_model.dart';
import '../models/shift_model.dart';
import '../models/employee_model.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/payment_dialog.dart';
import 'dart:async';

class RestaurantProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<TableModel> tables = [];
  List<MenuItem> menu = [];
  List<OrderModel> activeOrders = [];
  List<EmployeeModel> _employees = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<MenuItem>>? _menuSubscription;
  StreamSubscription<List<TableModel>>? _tablesSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;

  RestaurantProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _errorMessage = null;

      // Load initial data from Firestore
      menu = await _firestoreService.getMenu();
      tables = await _firestoreService.getTables();
      activeOrders = await _firestoreService.getActiveOrders(menu);
      _employees = await _firestoreService.getEmployees();
      debugPrint('Initial employees loaded: ${_employees.length} employees');

      // Setup real-time listeners
      _setupListeners();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi tải dữ liệu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupListeners() {
    // Menu stream listener
    _menuSubscription = _firestoreService.getMenuStream().listen(
      (items) {
        final oldMenuLength = menu.length;
        menu = items;

        // Always update orders listener when menu changes to ensure fresh data
        // This is important because orders contain menu item references
        if (oldMenuLength != items.length) {
          _updateOrdersListener();
        }

        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Lỗi khi đồng bộ menu: $error';
        notifyListeners();
      },
    );

    // Tables stream listener
    _tablesSubscription = _firestoreService.getTablesStream().listen(
      (tablesList) {
        tables = tablesList;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Lỗi khi đồng bộ bàn: $error';
        notifyListeners();
      },
    );

    // Orders stream listener - needs to update when menu changes
    _updateOrdersListener();

    // Employees stream listener
    _employeesSubscription = _firestoreService.getEmployeesStream().listen(
      (employees) {
        _employees = employees;
        debugPrint('Employees loaded: ${employees.length} employees');
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading employees: $error');
        _errorMessage = 'Lỗi khi đồng bộ nhân viên: $error';
        notifyListeners();
      },
    );
  }

  void _updateOrdersListener() {
    _ordersSubscription?.cancel();
    _ordersSubscription = _firestoreService
        .getActiveOrdersStream(menu)
        .listen(
          (orders) {
            activeOrders = orders;
            // Sync table statuses with actual orders
            _syncTableStatusesWithOrders();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Lỗi khi đồng bộ đơn hàng: $error';
            notifyListeners();
          },
        );
  }

  // Sync table statuses with actual orders
  // This fixes the issue where tables are marked as occupied but have no orders
  Future<void> _syncTableStatusesWithOrders() async {
    bool hasChanges = false;

    for (var table in tables) {
      // If table has currentOrderId but order doesn't exist, reset table status
      if (table.currentOrderId != null) {
        final orderExists = activeOrders.any(
          (order) => order.id == table.currentOrderId,
        );

        if (!orderExists) {
          // Order doesn't exist in active orders
          // Check if there are any other active orders for this table
          final tableOrders = activeOrders
              .where((order) => order.tableId == table.id)
              .toList();

          if (tableOrders.isEmpty) {
            // No active orders for this table
            // Reset to available regardless of current status (orders have been paid and deleted)
            if (table.status != TableStatus.available) {
              table.status = TableStatus.available;
              table.currentOrderId = null;
              hasChanges = true;

              // Update in Firestore
              try {
                await _firestoreService.updateTable(table);
              } catch (e) {
                debugPrint('Error syncing table ${table.id}: $e');
              }
            }
          } else {
            // There are other active orders for this table, update currentOrderId
            final latestOrder = tableOrders.first;
            if (table.currentOrderId != latestOrder.id) {
              table.currentOrderId = latestOrder.id;
              if (table.status != TableStatus.occupied) {
                table.status = TableStatus.occupied;
              }
              hasChanges = true;

              try {
                await _firestoreService.updateTable(table);
              } catch (e) {
                debugPrint('Error syncing table ${table.id}: $e');
              }
            }
          }
        } else {
          // Order exists, ensure table status is correct
          final order = activeOrders.firstWhere(
            (o) => o.id == table.currentOrderId,
          );
          if (order.status == OrderStatus.completed &&
              table.status == TableStatus.occupied) {
            table.status = TableStatus.paymentPending;
            hasChanges = true;

            try {
              await _firestoreService.updateTable(table);
            } catch (e) {
              debugPrint('Error syncing table ${table.id}: $e');
            }
          } else if (order.status != OrderStatus.completed &&
              table.status == TableStatus.paymentPending) {
            table.status = TableStatus.occupied;
            hasChanges = true;

            try {
              await _firestoreService.updateTable(table);
            } catch (e) {
              debugPrint('Error syncing table ${table.id}: $e');
            }
          }
        }
      } else {
        // Table has no currentOrderId, check if it should have one
        final tableOrders = activeOrders
            .where((order) => order.tableId == table.id)
            .toList();

        if (tableOrders.isNotEmpty && table.status == TableStatus.available) {
          // Table has orders but is marked as available, update it
          // BUT: Only do this if the table doesn't have currentOrderId = null
          // This prevents reverting tables that were just set to available after payment
          // If a table was just paid, it will have currentOrderId = null and status = available
          // We should only sync if there are truly new orders that need to be tracked
          final latestOrder = tableOrders.first;
          table.currentOrderId = latestOrder.id;
          if (latestOrder.status == OrderStatus.completed) {
            table.status = TableStatus.paymentPending;
          } else {
            table.status = TableStatus.occupied;
          }
          hasChanges = true;

          try {
            await _firestoreService.updateTable(table);
          } catch (e) {
            debugPrint('Error syncing table ${table.id}: $e');
          }
        } else if (tableOrders.isEmpty &&
            table.status != TableStatus.available) {
          // No active orders and table is not available - should be available
          table.status = TableStatus.available;
          table.currentOrderId = null;
          hasChanges = true;

          try {
            await _firestoreService.updateTable(table);
          } catch (e) {
            debugPrint('Error syncing table ${table.id}: $e');
          }
        }
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // Refresh data manually
  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      menu = await _firestoreService.getMenu();
      tables = await _firestoreService.getTables();
      activeOrders = await _firestoreService.getActiveOrders(menu);

      // Sync table statuses with actual orders
      await _syncTableStatusesWithOrders();

      // Re-setup listeners with updated menu
      _updateOrdersListener();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi làm mới dữ liệu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _menuSubscription?.cancel();
    _tablesSubscription?.cancel();
    _ordersSubscription?.cancel();
    _employeesSubscription?.cancel();
    super.dispose();
  }

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
  Future<bool> placeOrder(
    int tableId,
    List<OrderItem> items, {
    String? employeeId,
  }) async {
    if (items.isEmpty) return false;

    try {
      // Generate order ID from timestamp
      final orderId = DateTime.now().millisecondsSinceEpoch;

      // Create order with explicit pending status
      final newOrder = OrderModel(
        id: orderId,
        tableId: tableId,
        timestamp: DateTime.now(),
        items: items,
        status: OrderStatus.pending, // Explicitly set status
        employeeId: employeeId,
      );

      // Save order to Firestore
      await _firestoreService.addOrder(newOrder);

      // Update table status appropriately
      final tableIndex = tables.indexWhere((t) => t.id == tableId);
      if (tableIndex != -1) {
        tables[tableIndex].status = TableStatus.occupied;
        tables[tableIndex].currentOrderId = newOrder.id;
        await _firestoreService.updateTable(tables[tableIndex]);
      }

      // Add order to local list immediately for instant UI update
      activeOrders.insert(0, newOrder);
      notifyListeners();

      // Force refresh orders and tables from Firestore to ensure consistency
      // The stream will also update automatically, but this ensures immediate UI update
      await Future.wait([_refreshOrders(), _refreshTables()]);

      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi tạo đơn hàng: $e';
      notifyListeners();
      return false;
    }
  }

  // Kitchen: Advance order status
  Future<bool> advanceOrderStatus(int orderId) async {
    final orderIndex = activeOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) {
      _errorMessage = 'Không tìm thấy đơn hàng';
      notifyListeners();
      return false;
    }

    OrderModel order = activeOrders[orderIndex];
    OrderStatus newStatus;

    // Determine new status
    if (order.status == OrderStatus.pending) {
      newStatus = OrderStatus.cooking;
    } else if (order.status == OrderStatus.cooking) {
      newStatus = OrderStatus.readyToServe;
    } else if (order.status == OrderStatus.readyToServe) {
      newStatus = OrderStatus.completed;
    } else {
      _errorMessage = 'Không thể cập nhật trạng thái từ ${order.status.name}';
      notifyListeners();
      return false;
    }

    try {
      // Find the document ID for this order
      final orderDocId = await _firestoreService.findOrderDocumentId(orderId);

      if (orderDocId == null) {
        _errorMessage = 'Không tìm thấy document của đơn hàng';
        notifyListeners();
        return false;
      }

      // Update status in Firestore
      await _firestoreService.updateOrderStatus(orderDocId, newStatus);

      // Update local state immediately for instant UI feedback
      activeOrders[orderIndex].status = newStatus;

      // If order is completed, update table status
      if (newStatus == OrderStatus.completed) {
        final tableIndex = tables.indexWhere((t) => t.id == order.tableId);
        if (tableIndex != -1) {
          tables[tableIndex].status = TableStatus.paymentPending;
          await _firestoreService.updateTable(tables[tableIndex]);
        }
      }

      // Notify listeners immediately for instant UI update
      notifyListeners();

      // Force refresh from Firestore to ensure consistency
      // This will also update the stream listener
      await Future.wait([_refreshOrders(), _refreshTables()]);

      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật trạng thái đơn hàng: $e';
      notifyListeners();
      return false;
    }
  }

  // Get completed orders for a table (for payment)
  Future<List<OrderModel>> getCompletedOrdersForTable(int tableId) async {
    try {
      return await _firestoreService.getCompletedOrdersForTable(tableId, menu);
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy danh sách đơn hàng: $e';
      notifyListeners();
      return [];
    }
  }

  // Process payment for a table
  Future<bool> processPayment(
    int tableId,
    double totalAmount,
    double discountPercent,
    PaymentMethod paymentMethod,
  ) async {
    try {
      final tableIndex = tables.indexWhere((t) => t.id == tableId);
      if (tableIndex == -1) {
        _errorMessage = 'Không tìm thấy bàn';
        notifyListeners();
        return false;
      }

      // Get completed orders for this table
      final completedOrders = await getCompletedOrdersForTable(tableId);
      if (completedOrders.isEmpty) {
        _errorMessage = 'Không có đơn hàng để thanh toán';
        notifyListeners();
        return false;
      }

      // Get order IDs
      final orderIds = completedOrders.map((order) => order.id).toList();

      // Save payment record to Firestore
      await _firestoreService.savePayment(
        tableId: tableId,
        totalAmount: totalAmount,
        discountPercent: discountPercent,
        paymentMethod: paymentMethod.name,
        orderIds: orderIds,
      );

      // Mark orders as paid
      await _firestoreService.markOrdersAsPaid(orderIds);

      // Note: We keep orders in Firestore with isPaid=true for history/reporting
      // The filtering logic will automatically exclude paid orders from activeOrders

      // Remove paid orders from local activeOrders list immediately
      // This prevents sync from reverting table status
      activeOrders.removeWhere((order) => orderIds.contains(order.id));

      // Update table status to available
      tables[tableIndex].status = TableStatus.available;
      tables[tableIndex].currentOrderId = null;

      // Update table in Firestore
      await _firestoreService.updateTable(tables[tableIndex]);

      // Notify listeners immediately for instant UI update
      notifyListeners();

      // Refresh orders to ensure consistency (stream will update eventually)
      await _refreshOrders();

      // Refresh tables but skip sync to preserve the status we just set
      // The stream listener will handle any further updates
      try {
        final updatedTables = await _firestoreService.getTables();
        // Preserve the status we just set for this table
        final updatedTableIndex = updatedTables.indexWhere(
          (t) => t.id == tableId,
        );
        if (updatedTableIndex != -1) {
          updatedTables[updatedTableIndex].status = TableStatus.available;
          updatedTables[updatedTableIndex].currentOrderId = null;
        }
        tables = updatedTables;
        notifyListeners();
      } catch (e) {
        // Silent fail - stream will handle updates
      }

      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi xử lý thanh toán: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager Stats
  double get dailyRevenue => activeOrders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0, (total, o) => total + o.total);

  int get totalOrders => activeOrders.length;

  int get pendingOrders =>
      activeOrders.where((o) => o.status == OrderStatus.pending).length;

  int get cookingOrders =>
      activeOrders.where((o) => o.status == OrderStatus.cooking).length;

  int get readyOrders =>
      activeOrders.where((o) => o.status == OrderStatus.readyToServe).length;

  int get completedOrders =>
      activeOrders.where((o) => o.status == OrderStatus.completed).length;

  int get totalTables => tables.length;

  int get availableTables =>
      tables.where((t) => t.status == TableStatus.available).length;

  int get occupiedTables =>
      tables.where((t) => t.status == TableStatus.occupied).length;

  int get paymentPendingTables =>
      tables.where((t) => t.status == TableStatus.paymentPending).length;

  int get totalMenuItems => menu.length;

  int get foodItems =>
      menu.where((m) => m.category == MenuCategory.food).length;

  int get drinkItems =>
      menu.where((m) => m.category == MenuCategory.drink).length;

  // Get best selling items from completed orders
  List<MapEntry<MenuItem, int>> get bestSellingItems {
    final Map<int, int> itemCounts = {};
    final Map<int, MenuItem> itemMap = {};

    // Build menu item map for quick lookup
    for (var item in menu) {
      itemMap[item.id] = item;
    }

    // Count items from completed orders
    for (var order in activeOrders.where(
      (o) => o.status == OrderStatus.completed,
    )) {
      for (var orderItem in order.items) {
        final itemId = orderItem.menuItem.id;
        itemCounts[itemId] = (itemCounts[itemId] ?? 0) + orderItem.quantity;
      }
    }

    // Sort by quantity descending and return top 5
    final sortedEntries = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(5)
        .where((entry) => itemMap.containsKey(entry.key))
        .map((entry) => MapEntry(itemMap[entry.key]!, entry.value))
        .toList();
  }

  // Manager: Add new menu item
  Future<bool> addMenuItem(MenuItem item) async {
    try {
      await _firestoreService.addMenuItem(item);
      // Force refresh menu to ensure UI updates immediately
      await _refreshMenu();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm món ăn: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager: Update menu item
  Future<bool> updateMenuItem(int id, MenuItem updatedItem) async {
    try {
      await _firestoreService.updateMenuItem(id, updatedItem);
      // Force refresh menu to ensure UI updates immediately
      await _refreshMenu();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật món ăn: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager: Delete menu item
  Future<bool> deleteMenuItem(int id) async {
    try {
      await _firestoreService.deleteMenuItem(id);
      // Force refresh menu to ensure UI updates immediately
      await _refreshMenu();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa món ăn: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager: Add new table
  Future<bool> addTable(TableModel table) async {
    try {
      await _firestoreService.addTable(table);
      await _refreshTables();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm bàn: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager: Update table
  Future<bool> updateTable(TableModel table) async {
    try {
      await _firestoreService.updateTable(table);
      await _refreshTables();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật bàn: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager: Delete table
  Future<bool> deleteTable(int tableId) async {
    try {
      await _firestoreService.deleteTable(tableId);
      await _refreshTables();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa bàn: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager: Update table status
  Future<bool> updateTableStatus(int tableId, TableStatus status) async {
    try {
      final tableIndex = tables.indexWhere((t) => t.id == tableId);
      if (tableIndex != -1) {
        tables[tableIndex].status = status;
        await _firestoreService.updateTable(tables[tableIndex]);
        await _refreshTables();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật trạng thái bàn: $e';
      notifyListeners();
      return false;
    }
  }

  // Refresh menu data
  Future<void> _refreshMenu() async {
    try {
      final updatedMenu = await _firestoreService.getMenu();
      menu = updatedMenu;
      // Update orders listener with new menu
      _updateOrdersListener();
      notifyListeners();
    } catch (e) {
      // Silent fail - stream will handle updates
    }
  }

  // Refresh orders data
  Future<void> _refreshOrders() async {
    try {
      final updatedOrders = await _firestoreService.getActiveOrders(menu);
      activeOrders = updatedOrders;
      // Sync table statuses with actual orders after refresh
      await _syncTableStatusesWithOrders();
      notifyListeners();
    } catch (e) {
      // Silent fail - stream will handle updates
    }
  }

  // Refresh tables data
  Future<void> _refreshTables() async {
    try {
      final updatedTables = await _firestoreService.getTables();
      tables = updatedTables;
      // Sync table statuses with actual orders after refresh
      await _syncTableStatusesWithOrders();
      notifyListeners();
    } catch (e) {
      // Silent fail - stream will handle updates
    }
  }

  // ========== REPORTS ==========

  // Generate report for a specific type (latest period)
  Future<ReportModel> generateReport(ReportType type) async {
    final now = DateTime.now();
    DateTime startDate;

    switch (type) {
      case ReportType.weekly:
        // Get start of week (Monday)
        final weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day - (weekday - 1));
        break;
      case ReportType.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ReportType.yearly:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return await generateReportForDate(type, startDate);
  }

  // Generate report for a specific date
  Future<ReportModel> generateReportForDate(
    ReportType type,
    DateTime date,
  ) async {
    DateTime startDate;
    DateTime endDate;

    switch (type) {
      case ReportType.weekly:
        // Get start of week (Monday)
        final weekday = date.weekday;
        startDate = DateTime(date.year, date.month, date.day - (weekday - 1));
        endDate = DateTime(
          date.year,
          date.month,
          date.day - (weekday - 1) + 6,
          23,
          59,
          59,
        );
        break;
      case ReportType.monthly:
        startDate = DateTime(date.year, date.month, 1);
        endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        break;
      case ReportType.yearly:
        startDate = DateTime(date.year, 1, 1);
        endDate = DateTime(date.year, 12, 31, 23, 59, 59);
        break;
    }

    // Get completed orders in range
    final orders = await _firestoreService.getCompletedOrdersInRange(
      startDate,
      endDate,
      menu,
    );

    // Calculate statistics
    double totalRevenue = 0.0;
    final Map<String, int> itemSales = {}; // menuItemId -> quantity
    final Map<String, double> itemRevenue = {}; // menuItemId -> revenue

    for (var order in orders) {
      totalRevenue += order.total;

      for (var orderItem in order.items) {
        final itemId = orderItem.menuItem.id.toString();
        final quantity = orderItem.quantity;
        final revenue = orderItem.menuItem.price * quantity;

        itemSales[itemId] = (itemSales[itemId] ?? 0) + quantity;
        itemRevenue[itemId] = (itemRevenue[itemId] ?? 0.0) + revenue;
      }
    }

    // Create report model
    final report = ReportModel(
      id: '', // Will be set when saved
      type: type,
      startDate: startDate,
      endDate: endDate,
      totalRevenue: totalRevenue,
      totalOrders: orders.length,
      itemSales: itemSales,
      itemRevenue: itemRevenue,
    );

    return report;
  }

  // Save report to Firestore
  Future<bool> saveReport(ReportModel report) async {
    try {
      await _firestoreService.saveReport(report);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi lưu báo cáo: $e';
      notifyListeners();
      return false;
    }
  }

  // Get saved reports
  Future<List<ReportModel>> getSavedReports(
    ReportType type, {
    int limit = 30,
  }) async {
    try {
      return await _firestoreService.getReports(type, limit: limit);
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy báo cáo: $e';
      notifyListeners();
      return [];
    }
  }

  // ========== SHIFTS ==========

  // Employees list from Firestore (chỉ lấy nhân viên đang hoạt động)
  List<Map<String, String>> get employees {
    final activeEmployees = _employees
        .where((emp) => emp.isActive) // Chỉ lấy nhân viên đang hoạt động
        .map((emp) => {'id': emp.id, 'name': emp.name})
        .toList();
    debugPrint('Active employees: ${activeEmployees.length}');
    return activeEmployees;
  }

  // Get shifts stream
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firestoreService.getShiftsStream();
  }

  // Get all shifts (once)
  Future<List<ShiftModel>> getShifts() async {
    try {
      return await _firestoreService.getShifts();
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy ca làm: $e';
      notifyListeners();
      return [];
    }
  }

  // Refresh shifts
  Future<void> refreshShifts() async {
    // Stream will automatically update
    notifyListeners();
  }

  // Add shift
  Future<bool> addShift(ShiftModel shift) async {
    try {
      await _firestoreService.addShift(shift);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm ca làm: $e';
      notifyListeners();
      return false;
    }
  }

  // Update shift
  Future<bool> updateShift(ShiftModel shift) async {
    try {
      await _firestoreService.updateShift(shift);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật ca làm: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete shift
  Future<bool> deleteShift(String shiftId) async {
    try {
      await _firestoreService.deleteShift(shiftId);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa ca làm: $e';
      notifyListeners();
      return false;
    }
  }

  // Get shifts for employee
  Future<List<ShiftModel>> getShiftsForEmployee(String employeeId) async {
    try {
      return await _firestoreService.getShiftsForEmployee(employeeId);
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy ca làm: $e';
      notifyListeners();
      return [];
    }
  }

  // Get shifts in current week for employee
  Future<List<ShiftModel>> getCurrentWeekShiftsForEmployee(
    String employeeId,
  ) async {
    try {
      final now = DateTime.now();
      final weekday = now.weekday;
      final weekStart = now.subtract(Duration(days: weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final allShifts = await _firestoreService.getShiftsForEmployee(
        employeeId,
      );
      return allShifts.where((shift) {
        final shiftDate = DateTime(
          shift.date.year,
          shift.date.month,
          shift.date.day,
        );
        return shiftDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            shiftDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy ca làm: $e';
      notifyListeners();
      return [];
    }
  }

  // Check for overlapping shifts
  Future<List<ShiftModel>> checkOverlappingShifts(
    String employeeId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    String? excludeShiftId,
  }) async {
    try {
      return await _firestoreService.checkOverlappingShifts(
        employeeId,
        date,
        startTime,
        endTime,
        excludeShiftId: excludeShiftId,
      );
    } catch (e) {
      _errorMessage = 'Lỗi khi kiểm tra ca làm trùng: $e';
      notifyListeners();
      return [];
    }
  }

  // ========== EMPLOYEES ==========

  // Get employees stream
  Stream<List<EmployeeModel>> getEmployeesStream() {
    return _firestoreService.getEmployeesStream();
  }

  // Get all employees (once)
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      return await _firestoreService.getEmployees();
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy danh sách nhân viên: $e';
      notifyListeners();
      return [];
    }
  }

  // Add employee
  Future<bool> addEmployee(EmployeeModel employee) async {
    try {
      await _firestoreService.addEmployee(employee);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm nhân viên: $e';
      notifyListeners();
      return false;
    }
  }

  // Update employee
  Future<bool> updateEmployee(EmployeeModel employee) async {
    try {
      await _firestoreService.updateEmployee(employee);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật nhân viên: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      await _firestoreService.deleteEmployee(employeeId);
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa nhân viên: $e';
      notifyListeners();
      return false;
    }
  }

  // Get employee by username
  Future<EmployeeModel?> getEmployeeByUsername(String username) async {
    try {
      return await _firestoreService.getEmployeeByUsername(username);
    } catch (e) {
      _errorMessage = 'Lỗi khi tìm nhân viên: $e';
      notifyListeners();
      return null;
    }
  }
}
