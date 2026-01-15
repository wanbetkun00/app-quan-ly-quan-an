import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/restaurant_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/vnd_format.dart';
import '../utils/input_sanitizer.dart';
import 'dart:io';

class OrderingSheet extends StatefulWidget {
  final int tableId;
  const OrderingSheet({super.key, required this.tableId});

  @override
  State<OrderingSheet> createState() => _OrderingSheetState();
}

class _OrderingSheetState extends State<OrderingSheet>
    with SingleTickerProviderStateMixin {
  List<OrderItem> draftItems = [];
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addToDraft(MenuItem item) {
    setState(() {
      final existingIndex = draftItems.indexWhere(
        (i) => i.menuItem.id == item.id,
      );
      if (existingIndex != -1) {
        draftItems[existingIndex].quantity++;
      } else {
        draftItems.add(OrderItem(menuItem: item, quantity: 1));
      }
    });
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${item.name}'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: AppTheme.statusGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFromDraft(int index) {
    setState(() {
      if (draftItems[index].quantity > 1) {
        draftItems[index].quantity--;
      } else {
        draftItems.removeAt(index);
      }
    });
  }

  double get _draftTotal => draftItems.fold(
    0,
    (sum, item) => sum + (item.menuItem.price * item.quantity),
  );

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    final foodMenu = provider.menu
        .where((m) => m.category == MenuCategory.food)
        .toList();
    final drinkMenu = provider.menu
        .where((m) => m.category == MenuCategory.drink)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.strings.orderingForTable(widget.tableId),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (draftItems.isNotEmpty)
                          Text(
                            '${draftItems.length} món đã chọn',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ăn...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGreyBg,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = InputSanitizer.sanitizeSearchQuery(value);
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryOrange,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant, size: 18),
                        const SizedBox(width: 8),
                        Text(context.strings.tabFood),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_drink, size: 18),
                        const SizedBox(width: 8),
                        Text(context.strings.tabDrinks),
                      ],
                    ),
                  ),
                ],
              ),

              // Menu content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMenuGrid(foodMenu, controller),
                    _buildMenuGrid(drinkMenu, controller),
                  ],
                ),
              ),

              // Order summary
              _buildOrderSummary(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid(List<MenuItem> items, ScrollController controller) {
    // Filter by search query
    final filteredItems = _searchQuery.isEmpty
        ? items
        : items
            .where((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy món nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (ctx, index) {
        final item = filteredItems[index];
        final draftItem = draftItems.firstWhere(
          (d) => d.menuItem.id == item.id,
          orElse: () => OrderItem(menuItem: item, quantity: 0),
        );
        
        return _buildMenuItemCard(item, draftItem.quantity);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item, int quantity) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: quantity > 0 ? 4 : 1,
      child: InkWell(
        onTap: () => _addToDraft(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: quantity > 0
                ? Border.all(
                    color: AppTheme.primaryOrange,
                    width: 2,
                  )
                : Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: item.imageUrl != null
                      ? item.imageUrl!.startsWith('http')
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(item.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                      : _buildPlaceholderImage(),
                ),
              ),
              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.price.toVnd(),
                            style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (quantity > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, RestaurantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draftItems.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: draftItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final item = draftItems[index];
                  return Dismissible(
                    key: Key('${item.menuItem.id}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) {
                      setState(() {
                        draftItems.removeAt(index);
                      });
                    },
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item.menuItem.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${item.menuItem.price.toVnd()} x ${item.quantity}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (item.menuItem.price * item.quantity).toVnd(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            color: Colors.red,
                            onPressed: () => _removeFromDraft(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.strings.totalLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _draftTotal.toVnd(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: draftItems.isEmpty
                ? null
                : () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final success = await provider.placeOrder(
                      widget.tableId,
                      draftItems,
                      employeeId: authProvider.employeeId,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? context.strings.orderSentSnack
                                : 'Lỗi khi gửi đơn hàng. Vui lòng thử lại.',
                          ),
                          backgroundColor: success
                              ? AppTheme.statusGreen
                              : AppTheme.statusRed,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send),
                const SizedBox(width: 8),
                Text(context.strings.sendToKitchenButton),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
