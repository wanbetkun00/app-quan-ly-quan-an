import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/vnd_format.dart';
import '../../widgets/animated_card.dart';
import 'dart:io';

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  OrderStatus? _selectedFilter;
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.lightGreyBg,
            appBar: _buildAppBar(context),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Filter orders
        var filteredOrders = provider.activeOrders;
        if (!_showCompleted) {
          filteredOrders = filteredOrders
              .where((o) => o.status != OrderStatus.completed)
              .toList();
        }
        
        if (_selectedFilter != null) {
          filteredOrders = filteredOrders
              .where((o) => o.status == _selectedFilter)
              .toList();
        }

        // Sort by timestamp (oldest first for pending, newest first for others)
        filteredOrders.sort((a, b) {
          if (a.status == OrderStatus.pending && b.status == OrderStatus.pending) {
            return a.timestamp.compareTo(b.timestamp); // Oldest first
          }
          return b.timestamp.compareTo(a.timestamp); // Newest first
        });

        return Scaffold(
          backgroundColor: AppTheme.lightGreyBg,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Filter Bar
              _buildFilterBar(context, filteredOrders),
              
              // Orders Grid
              Expanded(
                child: filteredOrders.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () => provider.refreshData(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return AnimatedCard(
                              delay: Duration(milliseconds: index * 50),
                              child: _buildOrderCard(
                                context,
                                filteredOrders[index],
                                provider,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(context.strings.kitchenTitle),
      backgroundColor: AppTheme.darkGreyText,
      foregroundColor: Colors.white,
      actions: [
        Consumer<RestaurantProvider>(
          builder: (context, provider, _) {
            final pendingCount = provider.activeOrders
                .where((o) => o.status == OrderStatus.pending)
                .length;
            if (pendingCount > 0) {
              return Badge(
                label: Text('$pendingCount'),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    setState(() {
                      _selectedFilter = OrderStatus.pending;
                    });
                  },
                  tooltip: '$pendingCount đơn chờ xử lý',
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        TextButton(
          onPressed: () {
            Provider.of<LanguageProvider>(context, listen: false).toggleLanguage();
          },
          child: Text(
            Provider.of<LanguageProvider>(context).languageCode,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, List<OrderModel> orders) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null, orders.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Chờ xử lý',
                    OrderStatus.pending,
                    orders.where((o) => o.status == OrderStatus.pending).length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Đang nấu',
                    OrderStatus.cooking,
                    orders.where((o) => o.status == OrderStatus.cooking).length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Sẵn sàng',
                    OrderStatus.readyToServe,
                    orders.where((o) => o.status == OrderStatus.readyToServe).length,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(_showCompleted ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: _showCompleted ? 'Ẩn đơn đã hoàn thành' : 'Hiện đơn đã hoàn thành',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status, int count) {
    final isSelected = _selectedFilter == status;
    Color chipColor;
    
    if (status == null) {
      chipColor = Colors.grey;
    } else {
      switch (status) {
        case OrderStatus.pending:
          chipColor = AppTheme.statusRed;
          break;
        case OrderStatus.cooking:
          chipColor = AppTheme.statusYellow;
          break;
        case OrderStatus.readyToServe:
          chipColor = AppTheme.statusGreen;
          break;
        default:
          chipColor = Colors.grey;
      }
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : chipColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? chipColor : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            context.strings.noActiveOrders,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Không có đơn hàng nào để hiển thị',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    RestaurantProvider provider,
  ) {
    Color statusColor;
    String statusText;
    String nextActionText;
    IconData nextActionIcon;
    Color actionColor;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = AppTheme.statusRed;
        statusText = 'CHỜ XỬ LÝ';
        nextActionText = context.strings.kdsStartCooking;
        nextActionIcon = Icons.local_fire_department;
        actionColor = AppTheme.statusRed;
        break;
      case OrderStatus.cooking:
        statusColor = AppTheme.statusYellow;
        statusText = 'ĐANG NẤU';
        nextActionText = context.strings.kdsReadyToServe;
        nextActionIcon = Icons.check_circle_outline;
        actionColor = AppTheme.statusYellow;
        break;
      case OrderStatus.readyToServe:
        statusColor = AppTheme.statusGreen;
        statusText = 'SẴN SÀNG';
        nextActionText = context.strings.kdsCompleteOrder;
        nextActionIcon = Icons.done_all;
        actionColor = AppTheme.statusGreen;
        break;
      case OrderStatus.completed:
        statusColor = Colors.grey;
        statusText = 'HOÀN TẤT';
        nextActionText = '';
        nextActionIcon = Icons.check;
        actionColor = Colors.grey;
        break;
    }

    final waitingTime = DateTime.now().difference(order.timestamp);
    final minutesWaiting = waitingTime.inMinutes;

    return InkWell(
      onTap: () => _showOrderDetails(context, order, provider, statusColor, nextActionText, nextActionIcon, actionColor),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.table_restaurant,
                                  size: 20,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Bàn ${order.tableId}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order #${order.id.toString().substring(order.id.toString().length - 4)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (minutesWaiting > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: minutesWaiting > 15 
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$minutesWaiting phút',
                            style: TextStyle(
                              fontSize: 11,
                              color: minutesWaiting > 15 ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Items List - Limited preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: order.items.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có món',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: order.items.length > 3 ? 3 : order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quantity Badge
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: statusColor, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Item Name
                                Expanded(
                                  child: Text(
                                    item.menuItem.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            // Footer with total and action
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order.items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '+ ${order.items.length - 3} món khác',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        order.total.toVnd(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreyText,
                        ),
                      ),
                    ],
                  ),
                  if (order.status != OrderStatus.completed) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final success = await provider.advanceOrderStatus(order.id);
                          if (context.mounted) {
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lỗi khi cập nhật trạng thái đơn hàng'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(nextActionIcon, size: 18),
                        label: Text(
                          nextActionText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(
    BuildContext context,
    OrderModel order,
    RestaurantProvider provider,
    Color statusColor,
    String nextActionText,
    IconData nextActionIcon,
    Color actionColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.table_restaurant, color: statusColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Bàn ${order.tableId}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.toString().substring(order.id.toString().length - 4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Items List - Full
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity Badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Item Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      item.menuItem.category == MenuCategory.food
                                          ? Icons.restaurant
                                          : Icons.local_drink,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.menuItem.category == MenuCategory.food
                                          ? 'Món ăn'
                                          : 'Thức uống',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item.menuItem.price.toVnd(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Item Image (if available)
                          if (item.menuItem.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.menuItem.imageUrl!.startsWith('http')
                                  ? Image.network(
                                      item.menuItem.imageUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const SizedBox.shrink();
                                      },
                                    )
                                  : _buildLocalImage(item.menuItem.imageUrl!),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer with total and action
            Container(
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.total.toVnd(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  if (order.status != OrderStatus.completed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final success = await provider.advanceOrderStatus(order.id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lỗi khi cập nhật trạng thái đơn hàng'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(nextActionIcon, size: 22),
                        label: Text(
                          nextActionText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'CHỜ XỬ LÝ';
      case OrderStatus.cooking:
        return 'ĐANG NẤU';
      case OrderStatus.readyToServe:
        return 'SẴN SÀNG';
      case OrderStatus.completed:
        return 'HOÀN TẤT';
    }
  }

  Widget _buildLocalImage(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        );
      }
    } catch (e) {
      // Ignore errors
    }
    return const SizedBox.shrink();
  }
}
