import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ordering_sheet.dart';
import '../../widgets/payment_dialog.dart';
import '../../widgets/animated_card.dart';
import '../../utils/vnd_format.dart';
import 'package:intl/intl.dart';
import 'shift_view_screen.dart';

class WaiterDashboardScreen extends StatefulWidget {
  const WaiterDashboardScreen({super.key});

  @override
  State<WaiterDashboardScreen> createState() => _WaiterDashboardScreenState();
}

class _WaiterDashboardScreenState extends State<WaiterDashboardScreen> {
  TableStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    // Filter tables by status
    var filteredTables = provider.tables;
    if (_statusFilter != null) {
      filteredTables = filteredTables
          .where((t) => t.status == _statusFilter)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGreyBg,
      appBar: AppBar(
        title: Text(context.strings.waiterTitle),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Ca làm của tôi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShiftViewScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => provider.refreshData(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: TextButton(
                onPressed: langProvider.toggleLanguage,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  langProvider.languageCode.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Trống', TableStatus.available),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đang dùng', TableStatus.occupied),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Chờ thanh toán',
                    TableStatus.paymentPending,
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTheme.statusGreen, 'Trống'),
                const SizedBox(width: 16),
                _buildLegendItem(AppTheme.statusRed, 'Đang dùng'),
                const SizedBox(width: 16),
                _buildLegendItem(AppTheme.statusYellow, 'Chờ thanh toán'),
              ],
            ),
          ),

          // Tables Grid
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTables.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bàn nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.refreshData(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: filteredTables.length,
                      itemBuilder: (context, index) {
                        final table = filteredTables[index];
                        return AnimatedCard(
                          delay: Duration(milliseconds: index * 50),
                          child: _buildTableCard(context, table, provider),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TableStatus? status) {
    final isSelected = _statusFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? status : null;
        });
      },
      selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryOrange,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryOrange : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    TableModel table,
    RestaurantProvider provider,
  ) {
    final statusColor = provider.getTableColor(table.status);
    final isAvailable = table.status == TableStatus.available;

    // Find current order if exists
    OrderModel? currentOrder;
    if (table.currentOrderId != null) {
      try {
        currentOrder = provider.activeOrders.firstWhere(
          (o) => o.id == table.currentOrderId,
        );
      } catch (e) {
        // Order not found or completed
      }
    }

    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isAvailable
            ? () {
                _showOrderingSheet(context, table);
              }
            : table.status == TableStatus.paymentPending
            ? () {
                _showPaymentDialog(context, table, provider);
              }
            : () {
                _showTableDetails(context, table, currentOrder, provider);
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: statusColor, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Table icon
                Icon(
                  isAvailable ? Icons.table_restaurant : Icons.restaurant,
                  size: 36,
                  color: statusColor,
                ),
                const SizedBox(height: 6),
                // Table name
                Text(
                  table.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreyText,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusText(table.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Order info if exists
                if (currentOrder != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đơn #${currentOrder.id.toString().substring(currentOrder.id.toString().length - 4)}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getOrderStatusText(currentOrder.status),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'TRỐNG';
      case TableStatus.occupied:
        return 'ĐANG DÙNG';
      case TableStatus.paymentPending:
        return 'CHỜ THANH TOÁN';
    }
  }

  String _getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ nấu';
      case OrderStatus.cooking:
        return 'Đang nấu';
      case OrderStatus.readyToServe:
        return 'Sẵn sàng';
      case OrderStatus.completed:
        return 'Hoàn thành';
    }
  }

  void _showOrderingSheet(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderingSheet(tableId: table.id),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    TableModel table,
    RestaurantProvider provider,
  ) async {
    // Show loading
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get completed orders for this table
      final orders = await provider.getCompletedOrdersForTable(table.id);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (orders.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có đơn hàng nào để thanh toán'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show payment dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) =>
              PaymentDialog(table: table, orders: orders),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải đơn hàng: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showTableDetails(
    BuildContext context,
    TableModel table,
    OrderModel? order,
    RestaurantProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        table.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: provider
                              .getTableColor(table.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(table.status),
                          style: TextStyle(
                            color: provider.getTableColor(table.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (order != null) ...[
                    Text(
                      'Đơn hàng hiện tại',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreyBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đơn #${order.id.toString().substring(order.id.toString().length - 4)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getOrderStatusColor(
                                    order.status,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getOrderStatusText(order.status),
                                  style: TextStyle(
                                    color: _getOrderStatusColor(order.status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thời gian: ${DateFormat('HH:mm').format(order.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.menuItem.name}',
                                  ),
                                  Text(
                                    (item.menuItem.price * item.quantity)
                                        .toVnd(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cộng:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                order.total.toVnd(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có đơn hàng',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (table.status == TableStatus.occupied && order == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showOrderingSheet(context, table);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm món'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.cooking:
        return Colors.blue;
      case OrderStatus.readyToServe:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.grey;
    }
  }
}
