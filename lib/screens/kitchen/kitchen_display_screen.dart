import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';

class KitchenDisplayScreen extends StatelessWidget {
  const KitchenDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    // Filter out completed orders to keep KDS clean
    final activeOrders = provider.activeOrders
        .where((o) => o.status != OrderStatus.completed)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.lightGreyBg,
      appBar: AppBar(
        title: Text(context.strings.kitchenTitle),
        backgroundColor: AppTheme.darkGreyText,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: langProvider.toggleLanguage,
            child: Text(
              langProvider.languageCode,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: activeOrders.isEmpty
          ? Center(
              child: Text(
                context.strings.noActiveOrders,
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                return _buildOrderTicket(
                  context,
                  activeOrders[index],
                  provider,
                );
              },
            ),
    );
  }

  Widget _buildOrderTicket(
    BuildContext context,
    OrderModel order,
    RestaurantProvider provider,
  ) {
    Color statusColor;
    String nextActionText;
    IconData nextActionIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = AppTheme.statusRed;
        nextActionText = context.strings.kdsStartCooking;
        nextActionIcon = Icons.local_fire_department;
        break;
      case OrderStatus.cooking:
        statusColor = AppTheme.statusYellow;
        nextActionText = context.strings.kdsReadyToServe;
        nextActionIcon = Icons.check_circle_outline;
        break;
      case OrderStatus.readyToServe:
        statusColor = AppTheme.statusGreen;
        nextActionText = context.strings.kdsCompleteOrder;
        nextActionIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        nextActionText = "";
        nextActionIcon = Icons.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ticket Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Table ${order.tableId}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "#${order.id} · ${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Chip(
                  label: Text(order.status.name.toUpperCase()),
                  backgroundColor: statusColor,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Items List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: order.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${item.quantity}x",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.menuItem.name,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Action Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                provider.advanceOrderStatus(order.id);
              },
              icon: Icon(nextActionIcon),
              label: Text(nextActionText),
            ),
          ),
        ],
      ),
    );
  }
}

