import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/vnd_format.dart';
import '../../widgets/add_menu_item_dialog.dart';
import '../../widgets/add_table_dialog.dart';
import '../../widgets/menu_item_uri_image.dart';
import '../../widgets/role_guard.dart';
import 'reports_screen.dart';
import 'shift_management_screen.dart';
import 'employee_management_screen.dart';
import 'manager_ai_chat_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:path_provider/path_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const List<Color> _chartPalette = [
  Color(0xFFFFB300), // Amber
  Color(0xFFFB8C00), // Orange
  Color(0xFFF4511E), // Deep Orange
  Color(0xFF8D6E63), // Brown
  Color(0xFF42A5F5), // Blue
];

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  bool _isExporting = false;

  Future<void> _exportToExcel(ManagerTodayOverviewData data) async {
    setState(() => _isExporting = true);
    try {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Dashboard_Overview'];
      excel.delete('Sheet1');

      CellStyle titleStyle = CellStyle(bold: true, fontSize: 14);
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('FFFF9800'),
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // Title
      sheetObject.appendRow([TextCellValue('TỔNG QUAN DOANH THU HÔM NAY')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;
      sheetObject.appendRow([TextCellValue('Ngày: ${DateFormat('dd/MM/yyyy').format(data.date)}')]);
      sheetObject.appendRow([TextCellValue('')]);

      // Summary
      sheetObject.appendRow([TextCellValue('TỔNG QUAN CHUNG')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheetObject.maxRows - 1)).cellStyle = titleStyle;
      sheetObject.appendRow([TextCellValue('Tổng doanh thu'), TextCellValue(data.totalRevenue.toVnd())]);
      sheetObject.appendRow([TextCellValue('Tổng giảm giá'), TextCellValue(data.totalDiscount.toVnd())]);
      sheetObject.appendRow([TextCellValue('Doanh thu tiền mặt'), TextCellValue(data.totalCashRevenue.toVnd())]);
      sheetObject.appendRow([TextCellValue('Doanh thu chuyển khoản'), TextCellValue(data.totalTransferRevenue.toVnd())]);
      sheetObject.appendRow([TextCellValue('Số hóa đơn đã thanh toán'), IntCellValue(data.totalPaidOrders)]);
      sheetObject.appendRow([TextCellValue('')]);

      // Detailed Orders
      final startOfDay = DateTime(data.date.year, data.date.month, data.date.day, 0, 0, 0);
      final endOfDay = DateTime(data.date.year, data.date.month, data.date.day, 23, 59, 59);
      final orders = await provider.getPaidCompletedOrdersInRange(startOfDay, endOfDay);
      final orderPaymentMethods = await provider.getOrderPaymentMethods(startOfDay, endOfDay);
      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

      sheetObject.appendRow([TextCellValue('CHI TIẾT CÁC ĐƠN HÀNG')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheetObject.maxRows - 1)).cellStyle = titleStyle;
      var detailedHeader = [
        TextCellValue('STT'),
        TextCellValue('Thời gian'),
        TextCellValue('Bàn sử dụng'),
        TextCellValue('Món ăn'),
        TextCellValue('Số lượng'),
        TextCellValue('Đơn giá'),
        TextCellValue('Thành tiền'),
        TextCellValue('Thanh toán'),
      ];
      sheetObject.appendRow(detailedHeader);
      for (var i = 0; i < detailedHeader.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheetObject.maxRows - 1)).cellStyle = headerStyle;
      }

      int detailedIndex = 1;
      for (var order in orders) {
        String timeStr = DateFormat('HH:mm dd/MM/yyyy').format(order.timestamp);
        String tableName = 'Bàn ${order.tableId}';
        try {
          final table = provider.tables.firstWhere((t) => t.id == order.tableId);
          tableName = table.name;
        } catch (_) {}

        final paymentMethod = orderPaymentMethods[order.id] ?? 'Chưa rõ';
        for (var item in order.items) {
          sheetObject.appendRow([
            IntCellValue(detailedIndex++),
            TextCellValue(timeStr),
            TextCellValue(tableName),
            TextCellValue(item.menuItem.name),
            IntCellValue(item.quantity),
            TextCellValue(item.menuItem.price.toVnd()),
            TextCellValue((item.menuItem.price * item.quantity).toVnd()),
            TextCellValue(paymentMethod),
          ]);
        }
      }
      sheetObject.appendRow([TextCellValue('')]);

      // Top selling items
      sheetObject.appendRow([TextCellValue('CHI TIẾT MÓN BÁN CHẠY')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheetObject.maxRows - 1)).cellStyle = titleStyle;
      var headerRow = [
        TextCellValue('STT'),
        TextCellValue('Tên món'),
        TextCellValue('Số lượng'),
        TextCellValue('Doanh thu'),
      ];
      sheetObject.appendRow(headerRow);
      for (var i = 0; i < headerRow.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheetObject.maxRows - 1)).cellStyle = headerStyle;
      }

      int idx = 1;
      for (var entry in data.topSellingItems) {
        final item = entry.key;
        final qty = entry.value;
        final rev = data.itemRevenue[item.id] ?? 0.0;
        sheetObject.appendRow([
          IntCellValue(idx++),
          TextCellValue(item.name),
          IntCellValue(qty),
          TextCellValue(rev.toVnd()),
        ]);
      }

      final fileBytes = excel.encode();
      final fileName = "Bao_cao_ngay_${DateFormat('dd_MM_yyyy').format(data.date)}.xlsx";

      if (kIsWeb) {
        final blob = html.Blob([fileBytes!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = "${directory.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã lưu file tại: $filePath'), backgroundColor: AppTheme.statusGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất Excel: $e'), backgroundColor: AppTheme.statusRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isWebWide = MediaQuery.of(context).size.width >= 1080;

    return RoleGuard(
      allowedRoles: const [UserRole.manager],
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
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
          ),
          floatingActionButton: isWebWide
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) => const ManagerAiChatScreen(),
                      ),
                    );
                  },
                  tooltip: 'Trợ lý AI',
                  child: const Icon(Icons.smart_toy_outlined),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final tabView = TabBarView(
                children: [
              // 1. Dashboard Tab
              Consumer<RestaurantProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.refreshData(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxContentWidth = constraints.maxWidth > 1280
                            ? 1240.0
                            : constraints.maxWidth;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: SizedBox(
                              width: maxContentWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with refresh button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.strings.mgrTodayOverview,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.refresh),
                                        onPressed: () => provider.refreshData(),
                                        tooltip: 'Làm mới',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTodayOverviewSection(context, provider),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // 2. Menu Management Tab
              RefreshIndicator(
                onRefresh: () => provider.refreshData(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: provider.menu.length + 1, // +1 for Add button
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
                      return _buildCenteredContent(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitleBanner(
                              context: context,
                              title: context.strings.mgrTabMenu,
                              icon: Icons.restaurant_menu,
                            ),
                            const SizedBox(height: 10),
                            _buildPrimaryActionButton(
                              context: context,
                              label: context.strings.mgrAddNewDish,
                              icon: Icons.add_circle_outline,
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
                            ),
                          ],
                        ),
                      );
                    }
                    final item = provider.menu[index - 1];
                    return _buildCenteredContent(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                      leading: item.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: MenuItemUriImage(
                                uri: item.imageUrl!,
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
                              ),
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
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            item.category.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                      ),
                    );
                  },
                ),
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
                      itemCount:
                          provider.tables.length + 1, // +1 for Add button
                      itemBuilder: (ctx, index) {
                        if (index == 0) {
                          return _buildCenteredContent(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitleBanner(
                                  context: context,
                                  title: context.strings.mgrTabTableManagement,
                                  icon: Icons.table_restaurant,
                                ),
                                const SizedBox(height: 10),
                                _buildPrimaryActionButton(
                                  context: context,
                                  label: context.strings.addNewTable,
                                  icon: Icons.table_restaurant_outlined,
                              onPressed: () async {
                                final result = await showDialog<TableModel>(
                                  context: context,
                                  builder: (context) => const AddTableDialog(),
                                );
                                if (result != null) {
                                  final success = await provider.addTable(
                                    result,
                                  );
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
                                
                            ),
                              ],
                            ),
                          );
                        }
                        final table = provider.tables[index - 1];
                        return _buildCenteredContent(
                          child: _buildTableCard(context, table, provider),
                        );
                      },
                    ),
                  );
                },
              ),

              // 4. Reports Tab
              _buildCenteredScreen(const ReportsScreen()),

              // 5. Shift Management Tab
              _buildCenteredScreen(const ShiftManagementScreen()),

              // 6. Employee Management Tab
              _buildCenteredScreen(const EmployeeManagementScreen()),
                ],
              );

              final isWebLayout = constraints.maxWidth >= 1080;

              if (isWebLayout) {
                return Row(
                  children: [
                    _buildManagerSidebar(context),
                    Expanded(child: tabView),
                  ],
                );
              }

              return Column(
                children: [
                  Material(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: AppTheme.primaryOrange,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                        ),
                      ),
                      isScrollable: true,
                      tabs: _buildManagerTabs(context),
                    ),
                  ),
                  Expanded(child: tabView),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Tab> _buildManagerTabs(BuildContext context) {
    return [
      Tab(text: context.strings.mgrTabDashboard),
      Tab(text: context.strings.mgrTabMenu),
      Tab(text: context.strings.mgrTabTableManagement),
      Tab(text: context.strings.mgrTabReports),
      Tab(text: context.strings.mgrTabShifts),
              Tab(text: context.strings.mgrTabStaff),
    ];
  }

  Widget _buildManagerSidebar(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final labels = [
      context.strings.mgrTabDashboard,
      context.strings.mgrTabMenu,
      context.strings.mgrTabTableManagement,
      context.strings.mgrTabReports,
      context.strings.mgrTabShifts,
      context.strings.mgrTabStaff,
      'Trợ lý AI',
    ];
    final icons = const [
      Icons.dashboard_outlined,
      Icons.restaurant_menu,
      Icons.table_restaurant,
      Icons.bar_chart,
      Icons.badge_outlined,
      Icons.groups_outlined,
      Icons.smart_toy_outlined,
    ];
    const int aiMenuIndex = 6;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.index;
        return Container(
          width: 220,
          margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: labels.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final isAiEntry = index == aiMenuIndex;
              final isSelected = !isAiEntry && index == selected;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  leading: Icon(
                    icons[index],
                    color: isSelected ? AppTheme.primaryOrange : Colors.grey[700],
                  ),
                  title: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryOrange : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    if (isAiEntry) {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const ManagerAiChatScreen(),
                        ),
                      );
                      return;
                    }
                    controller.animateTo(index);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTodayOverviewSection(
    BuildContext context,
    RestaurantProvider provider,
  ) {
    return FutureBuilder<ManagerTodayOverviewData>(
      future: provider.getManagerTodayOverviewData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.strings.mgrOverviewLoadFailed,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final pieSections = data.topSellingItems.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryOrange.withValues(alpha: 0.12),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_outlined, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.strings.mgrRevenueTodayWithDate(
                        DateFormat('dd/MM/yyyy').format(data.date),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (_isExporting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryOrange),
                      onPressed: () => _exportToExcel(data),
                      tooltip: 'Xuất Excel',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final revenueCard = _buildStatCard(
                  context,
                  context.strings.mgrRevenueSoldAmount,
                  data.totalRevenue.toVnd(),
                  Icons.payments_outlined,
                  AppTheme.statusGreen,
                );
                final discountCard = _buildStatCard(
                  context,
                  context.strings.mgrDiscountAmount,
                  data.totalDiscount.toVnd(),
                  Icons.discount_outlined,
                  AppTheme.primaryOrange,
                );
                final cashCard = _buildStatCard(
                  context,
                  context.strings.mgrCashAmount,
                  data.totalCashRevenue.toVnd(),
                  Icons.account_balance_wallet_outlined,
                  const Color(0xFF2E7D32),
                );
                final transferCard = _buildStatCard(
                  context,
                  context.strings.mgrTransferAmount,
                  data.totalTransferRevenue.toVnd(),
                  Icons.swap_horiz_rounded,
                  const Color(0xFF1565C0),
                );

                final isCompact = constraints.maxWidth < 760;
                final cardWidth = isCompact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: cardWidth, child: revenueCard),
                    SizedBox(width: cardWidth, child: discountCard),
                    SizedBox(width: cardWidth, child: cashCard),
                    SizedBox(width: cardWidth, child: transferCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOverviewContainer(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.mgrHourlyRevenueChart,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BarRevenuePainter(data.hourlyRevenue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildOverviewContainer(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.mgrTopItemsPieChart,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CustomPaint(
                            painter: _PieSalesPainter(pieSections),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: pieSections
                                .asMap()
                                .entries
                                .map(
                                  (e) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 7,
                                      backgroundColor:
                                          _chartPalette[e.key % _chartPalette.length],
                                    ),
                                    title: Text(
                                      e.value.key.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Text('${e.value.value}'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.strings.mgrSoldItemsTodayTitle,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  context.strings.mgrBillsCount(data.totalPaidOrders),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.topSellingItems.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.strings.mgrNoSoldItemsToday,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...data.topSellingItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value.key;
                final qty = entry.value.value;
                final rev = data.itemRevenue[item.id] ?? 0.0;
                return _buildOverviewContainer(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      child: Text('${idx + 1}'),
                    ),
                    title: Text(item.name),
                    subtitle: Text(context.strings.mgrSoldQtyToday(qty)),
                    trailing: Text(
                      rev.toVnd(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => _showSoldItemDetail(context, item, qty, rev),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showSoldItemDetail(
    BuildContext context,
    MenuItem item,
    int qty,
    double revenue,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.mgrCategoryLabel(
                item.category.name.toUpperCase(),
              ),
            ),
            const SizedBox(height: 8),
            Text(context.strings.mgrSoldQtyToday(qty)),
            const SizedBox(height: 8),
            Text(
              context.strings.mgrRevenueFromItem(revenue.toVnd()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.closeDialog),
          ),
        ],
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
        gradient: LinearGradient(
          colors: [
            iconColor.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
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

  Widget _buildOverviewContainer({
    required Widget child,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitleBanner({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryOrange.withValues(alpha: 0.14),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryOrange),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB14A), Color(0xFFEF6C00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withValues(alpha: 0.26),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredContent({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCenteredScreen(Widget child) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: child,
    );
  }

  static const List<Color> _chartPalette = [
    Color(0xFFEF6C00),
    Color(0xFF26A69A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];

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

class _BarRevenuePainter extends CustomPainter {
  final List<double> values;
  _BarRevenuePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 28.0; // chừa chỗ hiển thị nhãn giờ
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final gridPaint = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartHeight * i / 4;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        gridPaint,
      );
    }

    final maxVal = values.isEmpty
        ? 1.0
        : values.reduce(math.max) <= 0
            ? 1.0
            : values.reduce(math.max);

    final barCount = values.isEmpty ? 24 : values.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = math.max(2.0, slotWidth * 0.55);
    final barPaint = Paint()
      ..color = const Color(0xFFEF6C00)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final normalized = (values[i] / maxVal).clamp(0.0, 1.0);
      final barH = normalized * (chartHeight - 4);
      final centerX = leftPad + (i + 0.5) * slotWidth;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          topPad + chartHeight - barH,
          barWidth,
          barH,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, barPaint);

      final label = i.toString().padLeft(2, '0');
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 8.5, color: Colors.black54),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, topPad + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarRevenuePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _PieSalesPainter extends CustomPainter {
  final List<MapEntry<MenuItem, int>> sections;
  _PieSalesPainter(this.sections);

  @override
  void paint(Canvas canvas, Size size) {
    final total = sections.fold<int>(0, (sum, e) => sum + e.value);
    if (total <= 0) {
      final p = Paint()..color = Colors.grey.shade300;
      canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2.4, p);
      return;
    }
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2.4,
    );
    double start = -math.pi / 2;
    for (int i = 0; i < sections.length; i++) {
      final sweep = (sections[i].value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _chartPalette[
            i % _chartPalette.length];
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    final hole = Paint()..color = Colors.white;
    canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 5.2, hole);
  }

  @override
  bool shouldRepaint(covariant _PieSalesPainter oldDelegate) =>
      oldDelegate.sections != sections;
}
