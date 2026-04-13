import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String menuCollection = 'menu';
  static const String tablesCollection = 'tables';
  static const String ordersCollection = 'orders';
  static const String reportsCollection = 'reports';
  static const String shiftsCollection = 'shifts';
  static const String paymentsCollection = 'payments';
  static const String employeesCollection = 'employees';

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

  // Stream active orders (not paid) - requires menu
  // Includes pending, cooking, readyToServe, and completed orders that are not paid
  Stream<List<OrderModel>> getActiveOrdersStream(List<MenuItem> menu) {
    return _firestore
        .collection(ordersCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final activeStatuses = {
            'pending',
            'cooking',
            'readyToServe',
            'completed',
          };
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final status = data['status'] as String?;
                // Exclude paid orders - only show unpaid orders
                if (data['isPaid'] == true) {
                  return null;
                }
                if (status != null && !activeStatuses.contains(status)) {
                  return null;
                }
                return _orderFromFirestore(doc.id, data, menu);
              })
              .where((order) => order != null)
              .cast<OrderModel>()
              .toList();
        });
  }

  // Get active orders once (not paid) - requires menu
  // Includes pending, cooking, readyToServe, and completed orders that are not paid
  Future<List<OrderModel>> getActiveOrders(List<MenuItem> menu) async {
    final snapshot = await _firestore
        .collection(ordersCollection)
        .orderBy('timestamp', descending: true)
        .get();
    final activeStatuses = {'pending', 'cooking', 'readyToServe', 'completed'};
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final status = data['status'] as String?;
          // Exclude paid orders - only show unpaid orders
          if (data['isPaid'] == true) {
            return null;
          }
          if (status != null && !activeStatuses.contains(status)) {
            return null;
          }
          return _orderFromFirestore(doc.id, data, menu);
        })
        .where((order) => order != null)
        .cast<OrderModel>()
        .toList();
  }

  // Add order
  Future<String> addOrder(OrderModel order) async {
    final data = _orderToFirestore(order);
    data['isPaid'] = false;
    final docRef = await _firestore.collection(ordersCollection).add(data);
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

  Future<OrderModel?> getActiveOrderForTable(
    int tableId,
    List<MenuItem> menu,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(ordersCollection)
          .where('tableId', isEqualTo: tableId)
          .where('isPaid', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      final status = data['status'] as String?;
      final activeStatuses = {'pending', 'cooking', 'readyToServe', 'completed'};
      if (status != null && !activeStatuses.contains(status)) return null;
      return _orderFromFirestore(snapshot.docs.first.id, data, menu);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteOrderByOrderId(int orderId) async {
    final orderDocId = await findOrderDocumentId(orderId);
    if (orderDocId == null) return;
    await _firestore.collection(ordersCollection).doc(orderDocId).delete();
  }

  Future<void> moveOrderToTable({
    required int fromTableId,
    required int toTableId,
    required int orderId,
  }) async {
    final fromRef = _firestore.collection(tablesCollection).doc(fromTableId.toString());
    final toRef = _firestore.collection(tablesCollection).doc(toTableId.toString());
    final orderDocId = await findOrderDocumentId(orderId);
    if (orderDocId == null) {
      throw Exception('Không tìm thấy đơn hàng để dời bàn');
    }
    final orderRef = _firestore.collection(ordersCollection).doc(orderDocId);

    await _firestore.runTransaction((tx) async {
      final fromSnap = await tx.get(fromRef);
      final toSnap = await tx.get(toRef);
      final orderSnap = await tx.get(orderRef);

      if (!fromSnap.exists || !toSnap.exists || !orderSnap.exists) {
        throw Exception('Không tìm thấy dữ liệu bàn hoặc đơn hàng');
      }

      final fromData = fromSnap.data()!;
      final toData = toSnap.data()!;
      final fromStatus = fromData['status'] as String?;
      final toStatus = toData['status'] as String?;
      final fromCurrentOrderId = fromData['currentOrderId'] as int?;

      if ((fromStatus != 'occupied' && fromStatus != 'paymentPending') ||
          fromCurrentOrderId == null ||
          fromCurrentOrderId != orderId) {
        throw Exception('Bàn nguồn không hợp lệ để dời');
      }
      if (toStatus != 'available') {
        throw Exception('Bàn đích không còn trống');
      }

      tx.update(orderRef, {'tableId': toTableId});
      tx.update(fromRef, {'status': 'available', 'currentOrderId': null});
      tx.update(toRef, {'status': 'occupied', 'currentOrderId': orderId});
    });
  }

  // Get completed orders for a table - requires menu
  // Only returns orders that are completed but not yet paid
  Future<List<OrderModel>> getCompletedOrdersForTable(
    int tableId,
    List<MenuItem> menu,
  ) async {
    try {
      // Query completed orders that are not paid yet
      final snapshot = await _firestore
          .collection(ordersCollection)
          .where('tableId', isEqualTo: tableId)
          .where('status', isEqualTo: 'completed')
          .get();

      final orders = snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Only include orders that are not paid
            if (data['isPaid'] == true) {
              return null;
            }
            return _orderFromFirestore(doc.id, data, menu);
          })
          .where((order) => order != null)
          .cast<OrderModel>()
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
            .map((doc) {
              final data = doc.data();
              // Only include completed orders that are not paid
              if (data['status'] != 'completed' || data['isPaid'] == true) {
                return null;
              }
              return _orderFromFirestore(doc.id, data, menu);
            })
            .where((order) => order != null)
            .cast<OrderModel>()
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
    final map = <String, dynamic>{
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
    // Add employeeId if present
    if (order.employeeId != null) {
      map['employeeId'] = order.employeeId!;
    }
    return map;
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
      employeeId: data['employeeId'] as String?,
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
    required String verificationStatus,
    String? transferTransactionId,
    String? transferNote,
  }) async {
    try {
      await _firestore.collection(paymentsCollection).add({
        'tableId': tableId,
        'totalAmount': totalAmount,
        'discountPercent': discountPercent,
        'paymentMethod': paymentMethod,
        'verificationStatus': verificationStatus,
        'orderIds': orderIds,
        if (transferTransactionId != null && transferTransactionId.trim().isNotEmpty)
          'transferTransactionId': transferTransactionId.trim(),
        if (transferNote != null && transferNote.trim().isNotEmpty)
          'transferNote': transferNote.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi khi lưu thông tin thanh toán: $e');
    }
  }

  // Mark orders as paid
  // Firestore whereIn has a limit of 10 items, so we need to split queries
  Future<void> markOrdersAsPaid(List<int> orderIds) async {
    if (orderIds.isEmpty) return;

    try {
      final now = Timestamp.now();
      const int whereInLimit = 10; // Firestore limit for whereIn

      // Split orderIds into chunks of 10
      for (int i = 0; i < orderIds.length; i += whereInLimit) {
        final chunk = orderIds.skip(i).take(whereInLimit).toList();
        final batch = _firestore.batch();

        // Query orders in this chunk
        final snapshot = await _firestore
            .collection(ordersCollection)
            .where('id', whereIn: chunk)
            .get();

        // Update each order in batch
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'paidAt': now, 'isPaid': true});
        }

        // Commit this batch
        if (snapshot.docs.isNotEmpty) {
          await batch.commit();
        }
      }
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu đơn hàng đã thanh toán: $e');
    }
  }

  // Delete paid orders for a table
  // Firestore whereIn has a limit of 10 items, so we need to split queries
  Future<void> deletePaidOrdersForTable(int tableId, List<int> orderIds) async {
    if (orderIds.isEmpty) return;

    try {
      const int whereInLimit = 10; // Firestore limit for whereIn

      // Split orderIds into chunks of 10
      for (int i = 0; i < orderIds.length; i += whereInLimit) {
        final chunk = orderIds.skip(i).take(whereInLimit).toList();
        final batch = _firestore.batch();

        // Query paid orders in this chunk for this table
        final snapshot = await _firestore
            .collection(ordersCollection)
            .where('tableId', isEqualTo: tableId)
            .where('id', whereIn: chunk)
            .where('isPaid', isEqualTo: true)
            .get();

        // Delete each paid order
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Commit this batch
        if (snapshot.docs.isNotEmpty) {
          await batch.commit();
        }
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa đơn hàng đã thanh toán: $e');
    }
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

  // Get paid completed orders within date range
  Future<List<OrderModel>> getPaidCompletedOrdersInRange(
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
          .where('isPaid', isEqualTo: true)
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .get();

      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
          .toList();

      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return orders;
    } catch (e) {
      // Fallback: get all completed paid orders and filter manually
      try {
        final snapshot = await _firestore
            .collection(ordersCollection)
            .where('status', isEqualTo: 'completed')
            .where('isPaid', isEqualTo: true)
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
  Future<List<ShiftModel>> getShifts({bool forceServer = false}) async {
    try {
      final snapshot = await _firestore
          .collection(shiftsCollection)
          .orderBy('date', descending: false)
          .get(forceServer
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.serverAndCache));
      return snapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ShiftModel?> getShiftById(String shiftId) async {
    if (shiftId.isEmpty) return null;
    try {
      final doc =
          await _firestore.collection(shiftsCollection).doc(shiftId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ShiftModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('getShiftById: $e');
      return null;
    }
  }

  // Get shifts for a specific employee (gán tay hoặc đã đăng ký ca mở)
  Future<List<ShiftModel>> getShiftsForEmployee(String employeeId) async {
    try {
      final allShifts = await getShifts();
      final list = allShifts.where((s) => s.involvesEmployee(employeeId)).toList();
      list.sort((a, b) {
        final da = DateTime(a.date.year, a.date.month, a.date.day);
        final db = DateTime(b.date.year, b.date.month, b.date.day);
        final c = da.compareTo(db);
        if (c != 0) return c;
        final am = a.startTime.hour * 60 + a.startTime.minute;
        final bm = b.startTime.hour * 60 + b.startTime.minute;
        return am.compareTo(bm);
      });
      return list;
    } catch (e) {
      debugPrint('Error getShiftsForEmployee: $e');
      return [];
    }
  }

  // Get shifts in date range
  Future<List<ShiftModel>> getShiftsInRange(
    DateTime startDate,
    DateTime endDate,
    {bool forceServer = false,}
  ) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final snapshot = await _firestore
          .collection(shiftsCollection)
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp)
          .orderBy('date', descending: false)
          .get(forceServer
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.serverAndCache));

      return snapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // Fallback: get all and filter
      try {
        final allShifts = await getShifts(forceServer: forceServer);
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
    try {
      if (shift.openSlot) {
        if (shift.maxEmployees < 1) {
          throw Exception('Số người cần phải >= 1.');
        }
      } else if (shift.employeeId.isEmpty ||
          shift.employeeId == ShiftModel.openSlotEmployeeId) {
        throw Exception('Employee ID is empty. Cannot add shift.');
      }
      final shiftData = shift.toFirestore();
      debugPrint(
        'Adding shift: employeeId=${shift.employeeId}, date=${shift.date}',
      );
      final docRef = await _firestore
          .collection(shiftsCollection)
          .add(shiftData);
      debugPrint('Shift added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding shift: $e');
      rethrow;
    }
  }

  // Update shift
  Future<void> updateShift(ShiftModel shift) async {
    try {
      if (shift.id.isEmpty) {
        throw Exception('Shift ID is empty. Cannot update shift.');
      }
      if (shift.openSlot) {
        if (shift.maxEmployees < shift.registeredCount) {
          throw Exception(
            'Số người tối đa không được nhỏ hơn số người đã đăng ký (${shift.registeredCount}).',
          );
        }
      } else if (shift.employeeId.isEmpty ||
          shift.employeeId == ShiftModel.openSlotEmployeeId) {
        throw Exception('Employee ID is empty. Cannot update shift.');
      }
      final shiftData = shift.toFirestore();
      debugPrint(
        'Updating shift: id=${shift.id}, employeeId=${shift.employeeId}',
      );
      await _firestore
          .collection(shiftsCollection)
          .doc(shift.id)
          .update(shiftData);
      debugPrint('Shift updated successfully: ${shift.id}');
    } catch (e) {
      debugPrint('Error updating shift ${shift.id}: $e');
      rethrow;
    }
  }

  // Delete shift
  Future<void> deleteShift(String shiftId) async {
    await _firestore.collection(shiftsCollection).doc(shiftId).delete();
  }

  /// Xóa toàn bộ ca làm trong collection `shifts`.
  /// Trả về số document đã xóa.
  ///
  /// Lưu ý: Firestore giới hạn 500 operations/batch, nên mặc định dùng 400 để dư an toàn.
  Future<int> deleteAllShifts({int batchSize = 400}) async {
    if (batchSize < 1) batchSize = 1;
    if (batchSize > 450) batchSize = 450;

    var deleted = 0;
    while (true) {
      final snap = await _firestore
          .collection(shiftsCollection)
          .limit(batchSize)
          .get(const GetOptions(source: Source.server));

      if (snap.docs.isEmpty) {
        return deleted;
      }

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snap.docs.length;
    }
  }

  // Check for overlapping shifts for an employee on a specific date
  /// Gồm ca gán tay và ca mở mà nhân viên đã đăng ký (theo [ShiftModel.involvesEmployee]).
  Future<List<ShiftModel>> checkOverlappingShifts(
    String employeeId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    String? excludeShiftId,
  }) async {
    try {
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final shifts = await getShiftsInRange(
        dateStart,
        dateEnd,
        forceServer: true,
      );
      return shifts.where((shift) {
        if (excludeShiftId != null && shift.id == excludeShiftId) {
          return false;
        }
        if (shift.status == ShiftStatus.cancelled) return false;
        if (!shift.involvesEmployee(employeeId)) return false;
        return _isTimeOverlapping(
          startTime,
          endTime,
          shift.startTime,
          shift.endTime,
        );
      }).toList();
    } catch (e) {
      debugPrint('checkOverlappingShifts: $e');
      return [];
    }
  }

  /// Mọi ca trong ngày [date] trùng khoảng [startTime, endTime], bỏ qua [excludeShiftId].
  Future<List<ShiftModel>> getShiftsOverlappingTimeOnDate(
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    String? excludeShiftId,
  }) async {
    try {
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final shifts = await getShiftsInRange(
        dateStart,
        dateEnd,
        forceServer: true,
      );
      return shifts.where((shift) {
        if (excludeShiftId != null && shift.id == excludeShiftId) {
          return false;
        }
        if (shift.status == ShiftStatus.cancelled) return false;
        return _isTimeOverlapping(
          startTime,
          endTime,
          shift.startTime,
          shift.endTime,
        );
      }).toList();
    } catch (e) {
      debugPrint('getShiftsOverlappingTimeOnDate: $e');
      return [];
    }
  }

  /// Đăng ký ca mở. Trả về `true` nếu thành công, `false` nếu đã đủ người hoặc không phải ca mở.
  Future<bool> registerForOpenShift({
    required String shiftId,
    required String employeeId,
  }) async {
    final ref = _firestore.collection(shiftsCollection).doc(shiftId);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      final shift = ShiftModel.fromFirestore(snap.id, data);
      if (!shift.openSlot) return false;
      if (shift.registeredEmployeeIds.contains(employeeId)) return true;
      if (shift.registeredCount >= shift.maxEmployees) return false;
      final next = [...shift.registeredEmployeeIds, employeeId];
      transaction.update(ref, {'registeredEmployeeIds': next});
      return true;
    });
  }

  /// Hủy đăng ký ca mở.
  Future<bool> unregisterFromOpenShift({
    required String shiftId,
    required String employeeId,
  }) async {
    final ref = _firestore.collection(shiftsCollection).doc(shiftId);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      final shift = ShiftModel.fromFirestore(snap.id, data);
      if (!shift.openSlot) return false;
      if (!shift.registeredEmployeeIds.contains(employeeId)) return true;
      final next = shift.registeredEmployeeIds
          .where((id) => id != employeeId)
          .toList();
      transaction.update(ref, {'registeredEmployeeIds': next});
      return true;
    });
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

  // ========== EMPLOYEES ==========

  // Stream all employees
  Stream<List<EmployeeModel>> getEmployeesStream() {
    return _firestore
        .collection(employeesCollection)
        .snapshots()
        .map((snapshot) {
          debugPrint('Employees stream: ${snapshot.docs.length} documents');
          final employees = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  debugPrint(
                    'Employee doc ${doc.id}: name=${data['name']}, isActive=${data['isActive']}',
                  );
                  return EmployeeModel.fromFirestore(doc.id, data);
                } catch (e) {
                  debugPrint('Error parsing employee ${doc.id}: $e');
                  return null;
                }
              })
              .where((emp) => emp != null)
              .cast<EmployeeModel>()
              .toList();
          // Sort by name locally
          employees.sort((a, b) => a.name.compareTo(b.name));
          debugPrint('Parsed ${employees.length} employees');
          return employees;
        })
        .handleError((error) {
          debugPrint('Error in getEmployeesStream: $error');
          return <EmployeeModel>[];
        });
  }

  // Get employees once
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final snapshot = await _firestore.collection(employeesCollection).get();
      debugPrint('getEmployees: ${snapshot.docs.length} documents found');
      final employees = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              debugPrint(
                'Employee doc ${doc.id}: name=${data['name']}, isActive=${data['isActive']}',
              );
              return EmployeeModel.fromFirestore(doc.id, data);
            } catch (e) {
              debugPrint('Error parsing employee ${doc.id}: $e');
              return null;
            }
          })
          .where((emp) => emp != null)
          .cast<EmployeeModel>()
          .toList();
      // Sort by name locally
      employees.sort((a, b) => a.name.compareTo(b.name));
      debugPrint('getEmployees: parsed ${employees.length} employees');
      return employees;
    } catch (e) {
      debugPrint('Error getting employees: $e');
      return [];
    }
  }

  // Add employee
  Future<String> addEmployee(EmployeeModel employee) async {
    final username = employee.username.trim();
    if (username.isEmpty) {
      throw Exception('Username is empty. Cannot add employee.');
    }

    final docRef = _firestore.collection(employeesCollection).doc(username);
    final existing = await docRef.get();
    if (existing.exists) {
      throw Exception('Username already exists');
    }

    // Use docId = username to enforce unique username
    await docRef.set(employee.copyWith(id: username).toFirestore());
    return docRef.id;
  }

  // Update employee
  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      if (employee.id.isEmpty) {
        throw Exception('Employee ID is empty. Cannot update employee.');
      }
      await _firestore
          .collection(employeesCollection)
          .doc(employee.id)
          .update(employee.toFirestore());
      debugPrint('Employee updated successfully: ${employee.id}');
    } catch (e) {
      debugPrint('Error updating employee ${employee.id}: $e');
      rethrow;
    }
  }

  // Delete employee
  Future<void> deleteEmployee(String employeeId) async {
    await _firestore.collection(employeesCollection).doc(employeeId).delete();
  }

  // Get employee by username
  Future<EmployeeModel?> getEmployeeByUsername(String username) async {
    try {
      final normalized = username.trim();
      if (normalized.isEmpty) return null;

      // Preferred path: docId = username
      final directDoc = await _firestore
          .collection(employeesCollection)
          .doc(normalized)
          .get();
      if (directDoc.exists) {
        return EmployeeModel.fromFirestore(directDoc.id, directDoc.data()!);
      }

      // Backward compatibility: legacy employees stored with auto-id
      final snapshot = await _firestore
          .collection(employeesCollection)
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return EmployeeModel.fromFirestore(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      return null;
    }
  }
}
