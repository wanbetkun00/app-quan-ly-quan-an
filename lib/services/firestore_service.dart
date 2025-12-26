import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/report_model.dart';
import '../models/shift_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String menuCollection = 'menu';
  static const String tablesCollection = 'tables';
  static const String ordersCollection = 'orders';
  static const String reportsCollection = 'reports';
  static const String shiftsCollection = 'shifts';
  static const String paymentsCollection = 'payments';

  // ========== MENU ITEMS ==========

  // Stream menu items
  Stream<List<MenuItem>> getMenuStream() {
    return _firestore
        .collection(menuCollection)
        .orderBy('id')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _menuItemFromFirestore(doc.data()))
              .toList(),
        );
  }

  // Get menu items once
  Future<List<MenuItem>> getMenu() async {
    final snapshot = await _firestore
        .collection(menuCollection)
        .orderBy('id')
        .get();
    return snapshot.docs
        .map((doc) => _menuItemFromFirestore(doc.data()))
        .toList();
  }

  // Add menu item
  Future<void> addMenuItem(MenuItem item) async {
    await _firestore
        .collection(menuCollection)
        .doc(item.id.toString())
        .set(_menuItemToFirestore(item));
  }

  // Update menu item
  Future<void> updateMenuItem(int id, MenuItem item) async {
    await _firestore
        .collection(menuCollection)
        .doc(id.toString())
        .update(_menuItemToFirestore(item));
  }

  // Delete menu item
  Future<void> deleteMenuItem(int id) async {
    await _firestore.collection(menuCollection).doc(id.toString()).delete();
  }

  // Convert MenuItem to Firestore Map
  Map<String, dynamic> _menuItemToFirestore(MenuItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'price': item.price,
      'category': item.category.name,
      'imageUrl': item.imageUrl,
    };
  }

  // Convert Firestore Map to MenuItem
  MenuItem _menuItemFromFirestore(Map<String, dynamic> data) {
    return MenuItem(
      id: data['id'] as int,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      category: MenuCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => MenuCategory.food,
      ),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  // ========== TABLES ==========

  // Stream tables
  Stream<List<TableModel>> getTablesStream() {
    return _firestore
        .collection(tablesCollection)
        .orderBy('id')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _tableFromFirestore(doc.data()))
              .toList(),
        );
  }

  // Get tables once
  Future<List<TableModel>> getTables() async {
    final snapshot = await _firestore
        .collection(tablesCollection)
        .orderBy('id')
        .get();
    return snapshot.docs.map((doc) => _tableFromFirestore(doc.data())).toList();
  }

  // Add or update table
  Future<void> updateTable(TableModel table) async {
    await _firestore
        .collection(tablesCollection)
        .doc(table.id.toString())
        .set(_tableToFirestore(table), SetOptions(merge: true));
  }

  // Add new table
  Future<void> addTable(TableModel table) async {
    await _firestore
        .collection(tablesCollection)
        .doc(table.id.toString())
        .set(_tableToFirestore(table));
  }

  // Delete table
  Future<void> deleteTable(int tableId) async {
    await _firestore
        .collection(tablesCollection)
        .doc(tableId.toString())
        .delete();
  }

  // Initialize tables if empty
  Future<void> initializeTables(List<TableModel> tables) async {
    final batch = _firestore.batch();
    for (var table in tables) {
      final docRef = _firestore
          .collection(tablesCollection)
          .doc(table.id.toString());
      batch.set(docRef, _tableToFirestore(table));
    }
    await batch.commit();
  }

  // Initialize menu if empty
  Future<void> initializeMenu(List<MenuItem> menu) async {
    final batch = _firestore.batch();
    for (var item in menu) {
      final docRef = _firestore
          .collection(menuCollection)
          .doc(item.id.toString());
      batch.set(docRef, _menuItemToFirestore(item));
    }
    await batch.commit();
  }

  // Convert TableModel to Firestore Map
  Map<String, dynamic> _tableToFirestore(TableModel table) {
    return {
      'id': table.id,
      'name': table.name,
      'status': table.status.name,
      'currentOrderId': table.currentOrderId,
    };
  }

  // Convert Firestore Map to TableModel
  TableModel _tableFromFirestore(Map<String, dynamic> data) {
    return TableModel(
      id: data['id'] as int,
      name: data['name'] as String,
      status: TableStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TableStatus.available,
      ),
      currentOrderId: data['currentOrderId'] as int?,
    );
  }

  // ========== ORDERS ==========

  // Stream active orders (not completed) - requires menu
  Stream<List<OrderModel>> getActiveOrdersStream(List<MenuItem> menu) {
    return _firestore
        .collection(ordersCollection)
        .where('status', whereIn: ['pending', 'cooking', 'readyToServe'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
              .toList(),
        );
  }

  // Get active orders once - requires menu
  Future<List<OrderModel>> getActiveOrders(List<MenuItem> menu) async {
    final snapshot = await _firestore
        .collection(ordersCollection)
        .where('status', whereIn: ['pending', 'cooking', 'readyToServe'])
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
        .toList();
  }

  // Add order
  Future<String> addOrder(OrderModel order) async {
    final docRef = await _firestore
        .collection(ordersCollection)
        .add(_orderToFirestore(order));
    return docRef.id;
  }

  // Update order
  Future<void> updateOrder(String orderId, OrderModel order) async {
    await _firestore
        .collection(ordersCollection)
        .doc(orderId)
        .update(_orderToFirestore(order));
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection(ordersCollection).doc(orderId).update({
      'status': status.name,
    });
  }

  // Find order document ID by order ID
  Future<String?> findOrderDocumentId(int orderId) async {
    final snapshot = await _firestore
        .collection(ordersCollection)
        .where('id', isEqualTo: orderId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  // Get completed orders for a table - requires menu
  Future<List<OrderModel>> getCompletedOrdersForTable(
    int tableId,
    List<MenuItem> menu,
  ) async {
    try {
      // Query without orderBy first to avoid index requirement
      final snapshot = await _firestore
          .collection(ordersCollection)
          .where('tableId', isEqualTo: tableId)
          .where('status', isEqualTo: 'completed')
          .get();

      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
          .toList();

      // Sort manually by timestamp
      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return orders;
    } catch (e) {
      // If error, try without status filter
      try {
        final snapshot = await _firestore
            .collection(ordersCollection)
            .where('tableId', isEqualTo: tableId)
            .get();

        final orders = snapshot.docs
            .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
            .where((order) => order.status == OrderStatus.completed)
            .toList();

        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return orders;
      } catch (e2) {
        return [];
      }
    }
  }

  // Convert OrderModel to Firestore Map
  Map<String, dynamic> _orderToFirestore(OrderModel order) {
    return {
      'id': order.id,
      'tableId': order.tableId,
      'timestamp': Timestamp.fromDate(order.timestamp),
      'status': order.status.name,
      'items': order.items
          .map(
            (item) => {
              'menuItemId': item.menuItem.id,
              'menuItemName': item.menuItem.name,
              'menuItemPrice': item.menuItem.price,
              'quantity': item.quantity,
            },
          )
          .toList(),
    };
  }

  // Convert Firestore Map to OrderModel (with menu items)
  OrderModel _orderFromFirestore(
    String docId,
    Map<String, dynamic> data,
    List<MenuItem> menu,
  ) {
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((itemData) {
      final menuItemId = itemData['menuItemId'] as int;
      final quantity = itemData['quantity'] as int;
      // Try to find menu item from menu list, or create a temporary one
      MenuItem menuItem;
      try {
        menuItem = menu.firstWhere((m) => m.id == menuItemId);
      } catch (e) {
        // If menu item not found, create a temporary one from stored data
        menuItem = MenuItem(
          id: menuItemId,
          name: itemData['menuItemName'] as String? ?? 'Unknown',
          price: (itemData['menuItemPrice'] as num?)?.toDouble() ?? 0.0,
          category: MenuCategory.food,
        );
      }
      return OrderItem(menuItem: menuItem, quantity: quantity);
    }).toList();

    return OrderModel(
      id: data['id'] as int? ?? int.tryParse(docId) ?? 0,
      tableId: data['tableId'] as int,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: items,
    );
  }

  // ========== PAYMENTS ==========

  // Save payment record
  Future<void> savePayment({
    required int tableId,
    required double totalAmount,
    required double discountPercent,
    required String paymentMethod,
    required List<int> orderIds,
  }) async {
    await _firestore.collection(paymentsCollection).add({
      'tableId': tableId,
      'totalAmount': totalAmount,
      'discountPercent': discountPercent,
      'paymentMethod': paymentMethod,
      'orderIds': orderIds,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mark orders as paid
  Future<void> markOrdersAsPaid(List<int> orderIds) async {
    if (orderIds.isEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.now();

    // Query all orders at once
    final snapshot = await _firestore
        .collection(ordersCollection)
        .where('id', whereIn: orderIds)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'paidAt': now, 'isPaid': true});
    }

    await batch.commit();
  }

  // ========== REPORTS ==========

  // Get completed orders within date range
  Future<List<OrderModel>> getCompletedOrdersInRange(
    DateTime startDate,
    DateTime endDate,
    List<MenuItem> menu,
  ) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final snapshot = await _firestore
          .collection(ordersCollection)
          .where('status', isEqualTo: 'completed')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .get();

      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
          .toList();

      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return orders;
    } catch (e) {
      // Fallback: get all completed orders and filter manually
      try {
        final snapshot = await _firestore
            .collection(ordersCollection)
            .where('status', isEqualTo: 'completed')
            .get();

        final allOrders = snapshot.docs
            .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
            .toList();

        final filteredOrders = allOrders.where((order) {
          return order.timestamp.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              order.timestamp.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();

        filteredOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return filteredOrders;
      } catch (e2) {
        return [];
      }
    }
  }

  // Save report to Firestore
  Future<String> saveReport(ReportModel report) async {
    final docRef = await _firestore
        .collection(reportsCollection)
        .add(report.toFirestore());
    return docRef.id;
  }

  // Get reports by type
  Future<List<ReportModel>> getReports(
    ReportType type, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(reportsCollection)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // If error (maybe no index), get all and filter manually
      try {
        final snapshot = await _firestore
            .collection(reportsCollection)
            .orderBy('createdAt', descending: true)
            .limit(limit * 2)
            .get();

        final allReports = snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc.id, doc.data()))
            .where((report) => report.type == type)
            .take(limit)
            .toList();

        return allReports;
      } catch (e2) {
        return [];
      }
    }
  }

  // Get latest report by type
  Future<ReportModel?> getLatestReport(ReportType type) async {
    try {
      final reports = await getReports(type, limit: 1);
      return reports.isNotEmpty ? reports.first : null;
    } catch (e) {
      return null;
    }
  }

  // ========== SHIFTS ==========

  // Stream all shifts
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firestore
        .collection(shiftsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  // Get shifts once
  Future<List<ShiftModel>> getShifts() async {
    try {
      final snapshot = await _firestore
          .collection(shiftsCollection)
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get shifts for a specific employee
  Future<List<ShiftModel>> getShiftsForEmployee(String employeeId) async {
    try {
      final snapshot = await _firestore
          .collection(shiftsCollection)
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // Fallback: get all and filter
      try {
        final allShifts = await getShifts();
        return allShifts
            .where((shift) => shift.employeeId == employeeId)
            .toList();
      } catch (e2) {
        return [];
      }
    }
  }

  // Get shifts in date range
  Future<List<ShiftModel>> getShiftsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final snapshot = await _firestore
          .collection(shiftsCollection)
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // Fallback: get all and filter
      try {
        final allShifts = await getShifts();
        return allShifts.where((shift) {
          return shift.date.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              shift.date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  // Add shift
  Future<String> addShift(ShiftModel shift) async {
    final docRef = await _firestore
        .collection(shiftsCollection)
        .add(shift.toFirestore());
    return docRef.id;
  }

  // Update shift
  Future<void> updateShift(ShiftModel shift) async {
    await _firestore
        .collection(shiftsCollection)
        .doc(shift.id)
        .update(shift.toFirestore());
  }

  // Delete shift
  Future<void> deleteShift(String shiftId) async {
    await _firestore.collection(shiftsCollection).doc(shiftId).delete();
  }

  // Check for overlapping shifts for an employee on a specific date
  Future<List<ShiftModel>> checkOverlappingShifts(
    String employeeId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    String? excludeShiftId,
  }) async {
    try {
      // Get all shifts for this employee on this date
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(shiftsCollection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateEnd))
          .get();

      final shifts = snapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
          .where(
            (shift) => excludeShiftId == null || shift.id != excludeShiftId,
          )
          .toList();

      // Filter shifts that overlap with the given time range
      final overlappingShifts = shifts.where((shift) {
        return _isTimeOverlapping(
          startTime,
          endTime,
          shift.startTime,
          shift.endTime,
        );
      }).toList();

      return overlappingShifts;
    } catch (e) {
      // Fallback: get all and filter manually
      try {
        final allShifts = await getShiftsForEmployee(employeeId);
        final sameDateShifts = allShifts.where((shift) {
          final shiftDate = DateTime(
            shift.date.year,
            shift.date.month,
            shift.date.day,
          );
          final checkDate = DateTime(date.year, date.month, date.day);
          return shiftDate.isAtSameMomentAs(checkDate) &&
              (excludeShiftId == null || shift.id != excludeShiftId);
        }).toList();

        return sameDateShifts.where((shift) {
          return _isTimeOverlapping(
            startTime,
            endTime,
            shift.startTime,
            shift.endTime,
          );
        }).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  // Helper method to check if two time ranges overlap
  bool _isTimeOverlapping(
    TimeOfDay start1,
    TimeOfDay end1,
    TimeOfDay start2,
    TimeOfDay end2,
  ) {
    // Convert to minutes for easier comparison
    final start1Minutes = start1.hour * 60 + start1.minute;
    final end1Minutes = end1.hour * 60 + end1.minute;
    final start2Minutes = start2.hour * 60 + start2.minute;
    final end2Minutes = end2.hour * 60 + end2.minute;

    // Check if time ranges overlap
    // Two ranges overlap if: start1 < end2 && start2 < end1
    return start1Minutes < end2Minutes && start2Minutes < end1Minutes;
  }
}
