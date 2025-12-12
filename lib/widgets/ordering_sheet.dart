import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/restaurant_provider.dart';
import '../providers/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/vnd_format.dart';

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

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  void _addToDraft(MenuItem item) {
    setState(() {
      final existingIndex = draftItems.indexWhere(
        (i) => i.menuItem.id == item.id,
      );
      if (existingIndex != -1) {
        draftItems[existingIndex].quantity++;
      } else {
        draftItems.add(OrderItem(menuItem: item));
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
      initialChildSize: 0.9,
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  context.strings.orderingForTable(widget.tableId),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryOrange,
                tabs: [
                  Tab(text: context.strings.tabFood),
                  Tab(text: context.strings.tabDrinks),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMenuGrid(foodMenu, controller),
                    _buildMenuGrid(drinkMenu, controller),
                  ],
                ),
              ),
              _buildOrderSummary(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid(List<MenuItem> items, ScrollController controller) {
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _addToDraft(item),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.lightGreyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item.price.toVnd()),
              ],
            ),
          ),
        );
      },
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draftItems.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: draftItems.length,
                itemBuilder: (ctx, index) {
                  final item = draftItems[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item.quantity}x ${item.menuItem.name}"),
                      Text((item.menuItem.price * item.quantity).toVnd()),
                    ],
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _draftTotal.toVnd(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                    final success = await provider.placeOrder(widget.tableId, draftItems);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                              ? context.strings.orderSentSnack
                              : 'Lỗi khi gửi đơn hàng'),
                          backgroundColor: success 
                              ? AppTheme.statusGreen 
                              : AppTheme.statusRed,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(context.strings.sendToKitchenButton),
          ),
        ],
      ),
    );
  }
}

