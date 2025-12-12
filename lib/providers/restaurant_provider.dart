import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import 'dart:async';

class RestaurantProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TableModel> tables = [];
  List<MenuItem> menu = [];
  List<OrderModel> activeOrders = [];
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  StreamSubscription<List<MenuItem>>? _menuSubscription;
  StreamSubscription<List<TableModel>>? _tablesSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  
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
  }
  
  void _updateOrdersListener() {
    _ordersSubscription?.cancel();
    _ordersSubscription = _firestoreService.getActiveOrdersStream(menu).listen(
      (orders) {
        activeOrders = orders;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Lỗi khi đồng bộ đơn hàng: $error';
        notifyListeners();
      },
    );
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
  Future<bool> placeOrder(int tableId, List<OrderItem> items) async {
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
      await Future.wait([
        _refreshOrders(),
        _refreshTables(),
      ]);
      
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
      await Future.wait([
        _refreshOrders(),
        _refreshTables(),
      ]);
      
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật trạng thái đơn hàng: $e';
      notifyListeners();
      return false;
    }
  }

  // Manager Stats
  double get dailyRevenue => activeOrders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0, (total, o) => total + o.total);
  
  int get totalOrders => activeOrders.length;
  
  int get pendingOrders => activeOrders.where((o) => o.status == OrderStatus.pending).length;
  
  int get cookingOrders => activeOrders.where((o) => o.status == OrderStatus.cooking).length;
  
  int get readyOrders => activeOrders.where((o) => o.status == OrderStatus.readyToServe).length;
  
  int get completedOrders => activeOrders.where((o) => o.status == OrderStatus.completed).length;
  
  int get totalTables => tables.length;
  
  int get availableTables => tables.where((t) => t.status == TableStatus.available).length;
  
  int get occupiedTables => tables.where((t) => t.status == TableStatus.occupied).length;
  
  int get paymentPendingTables => tables.where((t) => t.status == TableStatus.paymentPending).length;
  
  int get totalMenuItems => menu.length;
  
  int get foodItems => menu.where((m) => m.category == MenuCategory.food).length;
  
  int get drinkItems => menu.where((m) => m.category == MenuCategory.drink).length;
  
  // Get best selling items from completed orders
  List<MapEntry<MenuItem, int>> get bestSellingItems {
    final Map<int, int> itemCounts = {};
    final Map<int, MenuItem> itemMap = {};
    
    // Build menu item map for quick lookup
    for (var item in menu) {
      itemMap[item.id] = item;
    }
    
    // Count items from completed orders
    for (var order in activeOrders.where((o) => o.status == OrderStatus.completed)) {
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
      notifyListeners();
    } catch (e) {
      // Silent fail - stream will handle updates
    }
  }
}

