import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/vnd_format.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.strings.managerTitle),
          actions: [
            TextButton(
              onPressed: langProvider.toggleLanguage,
              child: Text(
                langProvider.languageCode,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: AppTheme.primaryOrange,
            indicatorColor: AppTheme.primaryOrange,
            tabs: [
              Tab(text: context.strings.mgrTabDashboard),
              Tab(text: context.strings.mgrTabMenu),
              Tab(text: context.strings.mgrTabStaff),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Dashboard Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.mgrTodayOverview,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        context.strings.mgrDailyRevenue,
                        provider.dailyRevenue.toVnd(),
                        Icons.attach_money,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        context.strings.mgrActiveOrders,
                        "${provider.activeOrders.where((o) => o.status != OrderStatus.completed).length}",
                        Icons.receipt_long,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.strings.mgrBestSellingDemo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // Placeholder list
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text("Phở bò đặc biệt"),
                      trailing: Text(
                        context.strings.soldUnits(24),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text("Coca-Cola"),
                      trailing: Text(
                        context.strings.soldUnits(45),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Menu Management Tab (Placeholder UI)
            ListView.builder(
              itemCount: provider.menu.length + 1, // +1 for Add button
              itemBuilder: (ctx, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: Text(context.strings.mgrAddNewDish),
                    ),
                  );
                }
                final item = provider.menu[index - 1];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.category.name.toUpperCase()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.price.toVnd(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),

            // 3. Staff Tab (Placeholder)
            Center(
              child: Text(
                context.strings.mgrStaffComingSoon,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

