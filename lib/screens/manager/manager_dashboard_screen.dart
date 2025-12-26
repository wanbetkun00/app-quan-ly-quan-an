import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/vnd_format.dart';
import '../../widgets/add_menu_item_dialog.dart';
import '../../widgets/add_table_dialog.dart';
import 'reports_screen.dart';
import 'shift_management_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return DefaultTabController(
      length: 5,
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
            isScrollable: true,
            tabs: [
              Tab(text: context.strings.mgrTabDashboard),
              Tab(text: context.strings.mgrTabMenu),
              Tab(text: context.strings.mgrTabTableManagement),
              Tab(text: context.strings.mgrTabReports),
              Tab(text: context.strings.mgrTabShifts),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Dashboard Tab
            Consumer<RestaurantProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refreshData(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with refresh button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.strings.mgrTodayOverview,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => provider.refreshData(),
                              tooltip: 'Làm mới',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Revenue and Orders Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                context.strings.mgrDailyRevenue,
                                provider.dailyRevenue.toVnd(),
                                Icons.attach_money,
                                AppTheme.statusGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                context.strings.mgrActiveOrders,
                                "${provider.totalOrders}",
                                Icons.receipt_long,
                                AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tables Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                context.strings.mgrTotalTables,
                                "${provider.totalTables}",
                                Icons.table_restaurant,
                                AppTheme.darkGreyText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                context.strings.mgrAvailableTables,
                                "${provider.availableTables}",
                                Icons.event_seat,
                                AppTheme.statusGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Menu Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                context.strings.mgrTotalMenuItems,
                                "${provider.totalMenuItems}",
                                Icons.restaurant_menu,
                                AppTheme.primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                context.strings.mgrFoodDrinks,
                                "${provider.foodItems} / ${provider.drinkItems}",
                                Icons.local_dining,
                                AppTheme.statusYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Best Selling Items
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.strings.mgrBestSellingDemo,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (provider.bestSellingItems.isEmpty)
                              Text(
                                context.strings.mgrNoDataYet,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        provider.bestSellingItems.isEmpty
                            ? Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      context.strings.mgrNoCompletedOrders,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: provider.bestSellingItems
                                    .asMap()
                                    .entries
                                    .map((indexedEntry) {
                                      final index = indexedEntry.key;
                                      final entry = indexedEntry.value;
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryOrange
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryOrange,
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Text(entry.key.name),
                                          subtitle: Text(
                                            entry.key.category.name
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${entry.value}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                context.strings.soldLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2. Menu Management Tab (Placeholder UI)
            ListView.builder(
              itemCount: provider.menu.length + 1, // +1 for Add button
              itemBuilder: (ctx, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<MenuItem>(
                          context: context,
                          builder: (context) => const AddMenuItemDialog(),
                        );
                        if (result != null) {
                          final success = await provider.addMenuItem(result);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Đã thêm "${result.name}" vào menu'
                                      : 'Lỗi khi thêm món ăn',
                                ),
                                backgroundColor: success
                                    ? AppTheme.statusGreen
                                    : AppTheme.statusRed,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(context.strings.mgrAddNewDish),
                    ),
                  );
                }
                final item = provider.menu[index - 1];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.imageUrl!.startsWith('http')
                                ? Image.network(
                                    item.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      );
                                    },
                                  )
                                : _buildLocalImage(item.imageUrl!),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: Colors.grey,
                            ),
                          ),
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
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await showDialog<MenuItem>(
                              context: context,
                              builder: (context) =>
                                  AddMenuItemDialog(itemToEdit: item),
                            );
                            if (result != null) {
                              final success = await provider.updateMenuItem(
                                item.id,
                                result,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Đã cập nhật "${result.name}"'
                                          : 'Lỗi khi cập nhật món ăn',
                                    ),
                                    backgroundColor: success
                                        ? AppTheme.statusGreen
                                        : AppTheme.statusRed,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: Text(
                                  'Bạn có chắc muốn xóa "${item.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(context.strings.cancelButton),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final success = await provider
                                          .deleteMenuItem(item.id);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? 'Đã xóa "${item.name}"'
                                                  : 'Lỗi khi xóa món ăn',
                                            ),
                                            backgroundColor: success
                                                ? AppTheme.statusRed
                                                : Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 3. Table Management Tab
            Consumer<RestaurantProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refreshData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.tables.length + 1, // +1 for Add button
                    itemBuilder: (ctx, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await showDialog<TableModel>(
                                context: context,
                                builder: (context) => const AddTableDialog(),
                              );
                              if (result != null) {
                                final success = await provider.addTable(result);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Đã thêm "${result.name}"'
                                            : 'Lỗi khi thêm bàn',
                                      ),
                                      backgroundColor: success
                                          ? AppTheme.statusGreen
                                          : AppTheme.statusRed,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(context.strings.addNewTable),
                          ),
                        );
                      }
                      final table = provider.tables[index - 1];
                      return _buildTableCard(context, table, provider);
                    },
                  ),
                );
              },
            ),

            // 4. Reports Tab
            const ReportsScreen(),

            // 5. Shift Management Tab
            const ShiftManagementScreen(),
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
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            );
          },
        );
      }
    } catch (e) {
      // Ignore errors
    }
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    TableModel table,
    RestaurantProvider provider,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (table.status) {
      case TableStatus.available:
        statusColor = AppTheme.statusGreen;
        statusText = context.strings.tableStatusAvailable;
        statusIcon = Icons.check_circle;
        break;
      case TableStatus.occupied:
        statusColor = AppTheme.statusRed;
        statusText = context.strings.tableStatusOccupied;
        statusIcon = Icons.restaurant;
        break;
      case TableStatus.paymentPending:
        statusColor = AppTheme.statusYellow;
        statusText = context.strings.tableStatusPaymentPending;
        statusIcon = Icons.payment;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: 2),
          ),
          child: Icon(statusIcon, color: statusColor, size: 28),
        ),
        title: Text(
          table.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (table.currentOrderId != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Order #${table.currentOrderId}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await showDialog<TableModel>(
                    context: context,
                    builder: (context) => AddTableDialog(tableToEdit: table),
                  );
                  if (result != null && context.mounted) {
                    final success = await provider.updateTable(result);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Đã cập nhật "${result.name}"'
                                : 'Lỗi khi cập nhật bàn',
                          ),
                          backgroundColor: success
                              ? AppTheme.statusGreen
                              : AppTheme.statusRed,
                        ),
                      );
                    }
                  }
                } else if (value == 'status') {
                  _showStatusDialog(context, table, provider);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, table, provider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'status',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Đổi trạng thái'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(
    BuildContext context,
    TableModel table,
    RestaurantProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi trạng thái ${table.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TableStatus.values.map((status) {
            String statusText;
            Color statusColor;
            switch (status) {
              case TableStatus.available:
                statusText = context.strings.tableStatusAvailable;
                statusColor = AppTheme.statusGreen;
                break;
              case TableStatus.occupied:
                statusText = context.strings.tableStatusOccupied;
                statusColor = AppTheme.statusRed;
                break;
              case TableStatus.paymentPending:
                statusText = context.strings.tableStatusPaymentPending;
                statusColor = AppTheme.statusYellow;
                break;
            }

            return ListTile(
              leading: Icon(
                table.status == status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: statusColor,
              ),
              title: Text(statusText),
              selected: table.status == status,
              onTap: () async {
                Navigator.pop(context);
                final success = await provider.updateTableStatus(
                  table.id,
                  status,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Đã cập nhật trạng thái'
                            : 'Lỗi khi cập nhật trạng thái',
                      ),
                      backgroundColor: success
                          ? AppTheme.statusGreen
                          : AppTheme.statusRed,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    TableModel table,
    RestaurantProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa "${table.name}"?\n\nLưu ý: Nếu bàn đang có đơn hàng, không thể xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (table.status != TableStatus.available) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Không thể xóa bàn đang có khách hoặc chờ thanh toán',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              final success = await provider.deleteTable(table.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Đã xóa "${table.name}"' : 'Lỗi khi xóa bàn',
                    ),
                    backgroundColor: success
                        ? AppTheme.statusRed
                        : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
