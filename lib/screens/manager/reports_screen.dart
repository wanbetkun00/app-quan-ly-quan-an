import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../models/menu_item.dart';
import '../../models/enums.dart';
import '../../utils/vnd_format.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.strings.reportsTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryOrange.withValues(alpha: 0.2),
            ),
          ),
          tabs: [
            Tab(text: context.strings.reportByWeek),
            Tab(text: context.strings.reportByMonth),
            Tab(text: context.strings.reportByYear),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportTabView(type: ReportType.weekly),
          _ReportTabView(type: ReportType.monthly),
          _ReportTabView(type: ReportType.yearly),
        ],
      ),
    );
  }
}

class _ReportTabView extends StatefulWidget {
  final ReportType type;

  const _ReportTabView({required this.type});

  @override
  State<_ReportTabView> createState() => _ReportTabViewState();
}

class _ReportTabViewState extends State<_ReportTabView> {
  bool _isLoading = false;
  ReportModel? _currentReport;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadLatestReport();
  }

  Future<void> _loadLatestReport() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      final report = await provider.generateReport(widget.type);
      if (mounted) {
        setState(() {
          _currentReport = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.strings.errorLoadingReport(e.toString())),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _selectDateAndGenerate() async {
    DateTime? picked;
    
    switch (widget.type) {
      case ReportType.weekly:
        // Select a date, then calculate week
        picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        break;
      case ReportType.monthly:
        // Show year/month picker
        final yearMonth = await _showYearMonthPicker();
        if (yearMonth != null) {
          picked = DateTime(yearMonth['year']!, yearMonth['month']!);
        }
        break;
      case ReportType.yearly:
        // Show year picker
        final year = await _showYearPicker();
        if (year != null) {
          picked = DateTime(year, 1, 1);
        }
        break;
    }

    if (picked != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<RestaurantProvider>(context, listen: false);
        final report = await provider.generateReportForDate(widget.type, picked);
        if (mounted) {
          setState(() {
            _currentReport = report;
            _selectedDate = picked;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.strings.errorGeneratingReport(e.toString())),
              backgroundColor: AppTheme.statusRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_currentReport == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final report = _currentReport!;
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Report'];
      excel.delete('Sheet1'); // Remove default sheet

      // Header style
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('FFFF9800'),
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      CellStyle titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
      );

      // Title & Info
      sheetObject.appendRow([TextCellValue('BÁO CÁO DOANH THU TKA')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheetObject.maxRows - 1)).cellStyle = titleStyle;
      
      sheetObject.appendRow([TextCellValue('Loại báo cáo: ${report.periodLabel}')]);
      sheetObject.appendRow([TextCellValue('Thời gian: ${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}')]);
      sheetObject.appendRow([TextCellValue('')]);

      // Summary
      sheetObject.appendRow([TextCellValue('TỔNG QUAN')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheetObject.maxRows - 1)).cellStyle = titleStyle;
      
      sheetObject.appendRow([TextCellValue('Tổng doanh thu'), TextCellValue(report.totalRevenue.toVnd())]);
      sheetObject.appendRow([TextCellValue('Tổng đơn hàng'), IntCellValue(report.totalOrders)]);
      sheetObject.appendRow([TextCellValue('Đơn trung bình'), TextCellValue(report.totalOrders > 0 ? (report.totalRevenue / report.totalOrders).toVnd() : '0₫')]);
      sheetObject.appendRow([TextCellValue('')]);

      // Detailed Orders
      final orders = await provider.getPaidCompletedOrdersInRange(report.startDate, report.endDate);
      final orderPaymentMethods = await provider.getOrderPaymentMethods(report.startDate, report.endDate);
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
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheetObject.maxRows - 1));
        cell.cellStyle = headerStyle;
      }

      int detailedIndex = 1;
      for (var order in orders) {
        String timeStr = '${order.timestamp.hour.toString().padLeft(2, '0')}:${order.timestamp.minute.toString().padLeft(2, '0')} '
            '${order.timestamp.day.toString().padLeft(2, '0')}/${order.timestamp.month.toString().padLeft(2, '0')}/${order.timestamp.year}';
        
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

      // Detailed Sales (Top Selling)
      sheetObject.appendRow([TextCellValue('CHI TIẾT MÓN BÁN CHẠY')]);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheetObject.maxRows - 1)).cellStyle = titleStyle;
      
      var headerRow = [
        TextCellValue('STT'),
        TextCellValue('Tên món'),
        TextCellValue('Số lượng'),
        TextCellValue('Giá bán'),
        TextCellValue('Thành tiền'),
      ];
      sheetObject.appendRow(headerRow);
      
      // Apply style to header row
      for (var i = 0; i < headerRow.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheetObject.maxRows - 1));
        cell.cellStyle = headerStyle;
      }

      final sortedEntries = report.itemSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      int index = 1;
      for (var entry in sortedEntries) {
        final menuItem = provider.menu.firstWhere(
          (item) => item.id.toString() == entry.key,
          orElse: () => MenuItem(id: 0, name: 'Unknown', price: 0, category: MenuCategory.food),
        );
        final revenue = report.itemRevenue[entry.key] ?? 0.0;
        
        sheetObject.appendRow([
          IntCellValue(index++),
          TextCellValue(menuItem.name),
          IntCellValue(entry.value),
          TextCellValue(menuItem.price.toVnd()),
          TextCellValue(revenue.toVnd()),
        ]);
      }

      var fileBytes = excel.encode();
      
      String periodName = '';
      switch (report.type) {
        case ReportType.weekly:
          periodName = report.periodLabel.replaceAll('Tuần ', 'Tuan_').replaceAll('/', '_');
          break;
        case ReportType.monthly:
          periodName = 'Thang_${report.periodLabel.replaceAll('/', '_')}';
          break;
        case ReportType.yearly:
          periodName = report.periodLabel.replaceAll('Năm ', 'Nam_');
          break;
      }
      final fileName = "Bao_cao_$periodName.xlsx";

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
            SnackBar(
              content: Text('Đã lưu file tại: $filePath'),
              backgroundColor: AppTheme.statusGreen,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất Excel: $e'),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, int>?> _showYearMonthPicker() async {
    int? selectedYear;
    int? selectedMonth;

    return showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentYear = DateTime.now().year;
            final years = List.generate(5, (i) => currentYear - i);
            final months = List.generate(12, (i) => i + 1);

            return AlertDialog(
              title: Text(context.strings.selectMonthYear),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.strings.yearLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: years.map((year) {
                      return ChoiceChip(
                        label: Text(year.toString()),
                        selected: selectedYear == year,
                        onSelected: (selected) {
                          setState(() => selectedYear = year);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(context.strings.monthLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: months.map((month) {
                      return ChoiceChip(
                        label: Text(month.toString()),
                        selected: selectedMonth == month,
                        onSelected: (selected) {
                          setState(() => selectedMonth = month);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.strings.cancelButton),
                ),
                ElevatedButton(
                  onPressed: (selectedYear != null && selectedMonth != null)
                      ? () => Navigator.pop(context, {
                            'year': selectedYear!,
                            'month': selectedMonth!,
                          })
                      : null,
                  child: Text(context.strings.selectButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int?> _showYearPicker() async {
    int? selectedYear;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentYear = DateTime.now().year;
            final years = List.generate(5, (i) => currentYear - i);

            return AlertDialog(
              title: Text(context.strings.selectYear),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.strings.yearLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: years.map((year) {
                      return ChoiceChip(
                        label: Text(year.toString()),
                        selected: selectedYear == year,
                        onSelected: (selected) {
                          setState(() => selectedYear = year);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.strings.cancelButton),
                ),
                ElevatedButton(
                  onPressed: selectedYear != null
                      ? () => Navigator.pop(context, selectedYear)
                      : null,
                  child: Text(context.strings.selectButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              context.strings.noReportData,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLatestReport,
              icon: const Icon(Icons.refresh),
              label: Text(context.strings.loadLatestReport),
            ),
          ],
        ),
      );
    }

    final report = _currentReport!;
    final provider = Provider.of<RestaurantProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadLatestReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodHeader(
              context,
              title: context.strings.reportForPeriod(report.periodLabel),
              periodText:
                  '${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}',
              onPickDate: _selectDateAndGenerate,
              onExport: _exportToExcel,
              tooltip: context.strings.selectDifferentDate,
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 760;
                final cardWidth = isCompact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context,
                        context.strings.totalRevenue,
                        report.totalRevenue.toVnd(),
                        Icons.attach_money,
                        AppTheme.statusGreen,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context,
                        context.strings.totalOrders,
                        '${report.totalOrders}',
                        Icons.receipt_long,
                        AppTheme.primaryOrange,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context,
                        context.strings.averageOrder,
                        report.totalOrders > 0
                            ? (report.totalRevenue / report.totalOrders).toVnd()
                            : '0₫',
                        Icons.trending_up,
                        AppTheme.statusYellow,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context,
                        context.strings.itemsSold,
                        '${report.itemSales.length}',
                        Icons.restaurant_menu,
                        AppTheme.darkGreyText,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Top Selling Items
            _buildSectionHeader(
              context,
              title: context.strings.mgrBestSellingDemo,
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: 12),
            if (report.itemSales.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      context.strings.noSalesData,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            else
              ...(() {
                final sortedEntries = report.itemSales.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final top10 = sortedEntries.take(10).toList();
                
                return top10.asMap().entries.map((entry) {
                  final index = entry.key;
                  final itemEntry = entry.value;
                  final menuItem = provider.menu.firstWhere(
                    (item) => item.id.toString() == itemEntry.key,
                    orElse: () => provider.menu.isNotEmpty ? provider.menu.first : MenuItem(
                      id: 0,
                      name: 'Unknown',
                      price: 0,
                      category: MenuCategory.food,
                    ),
                  );
                  final revenue = report.itemRevenue[itemEntry.key] ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
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
                      title: Text(menuItem.name),
                      subtitle: Text(
                        '${itemEntry.value} ${context.strings.units} • ${revenue.toVnd()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        menuItem.price.toVnd(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList();
              })(),

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

  Widget _buildPeriodHeader(
    BuildContext context, {
    required String title,
    required String periodText,
    required VoidCallback onPickDate,
    required VoidCallback onExport,
    required String tooltip,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  periodText,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Xuất Excel',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onExport,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.file_download_rounded, size: 18, color: Colors.green),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: tooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onPickDate,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryOrange),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

