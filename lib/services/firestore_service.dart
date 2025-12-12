import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String menuCollection = 'menu';
  static const String tablesCollection = 'tables';
  static const String ordersCollection = 'orders';

  // ========== MENU ITEMS ==========
  
  // Stream menu items
  Stream<List<MenuItem>> getMenuStream() {
    return _firestore
        .collection(menuCollection)
        .orderBy('id')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _menuItemFromFirestore(doc.data()))
            .toList());
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
    await _firestore
        .collection(menuCollection)
        .doc(id.toString())
        .delete();
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
        .map((snapshot) => snapshot.docs
            .map((doc) => _tableFromFirestore(doc.data()))
            .toList());
  }

  // Get tables once
  Future<List<TableModel>> getTables() async {
    final snapshot = await _firestore
        .collection(tablesCollection)
        .orderBy('id')
        .get();
    return snapshot.docs
        .map((doc) => _tableFromFirestore(doc.data()))
        .toList();
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
      final docRef = _firestore.collection(tablesCollection).doc(table.id.toString());
      batch.set(docRef, _tableToFirestore(table));
    }
    await batch.commit();
  }
  
  // Initialize menu if empty
  Future<void> initializeMenu(List<MenuItem> menu) async {
    final batch = _firestore.batch();
    for (var item in menu) {
      final docRef = _firestore.collection(menuCollection).doc(item.id.toString());
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
        .map((snapshot) => snapshot.docs
            .map((doc) => _orderFromFirestore(doc.id, doc.data(), menu))
            .toList());
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
    await _firestore
        .collection(ordersCollection)
        .doc(orderId)
        .update({'status': status.name});
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

  // Convert OrderModel to Firestore Map
  Map<String, dynamic> _orderToFirestore(OrderModel order) {
    return {
      'id': order.id,
      'tableId': order.tableId,
      'timestamp': Timestamp.fromDate(order.timestamp),
      'status': order.status.name,
      'items': order.items.map((item) => {
        'menuItemId': item.menuItem.id,
        'menuItemName': item.menuItem.name,
        'menuItemPrice': item.menuItem.price,
        'quantity': item.quantity,
      }).toList(),
    };
  }

  // Convert Firestore Map to OrderModel (with menu items)
  OrderModel _orderFromFirestore(String docId, Map<String, dynamic> data, List<MenuItem> menu) {
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

}

