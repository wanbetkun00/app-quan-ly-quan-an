import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import '../models/menu_item.dart';
import '../models/enums.dart';
import '../utils/vnd_format.dart';

class ExcelExportResult {
  final String filePath;
  final bool openSucceeded;
  final String? openMessage;

  const ExcelExportResult({
    required this.filePath,
    required this.openSucceeded,
    this.openMessage,
  });
}

class ExcelExportException implements Exception {
  final String message;

  const ExcelExportException(this.message);

  @override
  String toString() => message;
}

class ExcelExportService {
  /// Exports a report to Excel file
  ///
  /// [report] - The report model to export
  /// [menuItems] - List of menu items to resolve item names from IDs
  ///
  /// Returns detailed export result including open-file status
  Future<ExcelExportResult> exportReportToExcel({
    required ReportModel report,
    required List<MenuItem> menuItems,
  }) async {
    // Note: We use app-specific directory (getApplicationDocumentsDirectory)
    // which doesn't require storage permission on Android 13+ (API 33+)
    // and works without permission on older versions too.
    // No permission check needed - just proceed with file creation.
    // Create Excel workbook
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Delete default sheet

    // Create main sheet
    final sheet = excel['Báo cáo doanh thu'];

    // Build Excel content
    _buildExcelContent(sheet, report, menuItems);

    // Save Excel file
    final file = await _saveExcelFile(excel, report);

    // Open the file and return the status to UI
    final openResult = await OpenFile.open(file.path);
    return ExcelExportResult(
      filePath: file.path,
      openSucceeded: openResult.type == ResultType.done,
      openMessage: openResult.message,
    );
  }

  String _buildBaseFilename(ReportModel report) {
    switch (report.type) {
      case ReportType.weekly:
        final start = DateFormat('yyyy-MM-dd').format(report.startDate);
        return 'BaoCao_Tuan_$start';
      case ReportType.monthly:
        return 'BaoCao_Thang_${report.startDate.month}_${report.startDate.year}';
      case ReportType.yearly:
        return 'BaoCao_Nam_${report.startDate.year}';
    }
  }

  /// Builds the Excel content
  void _buildExcelContent(
    Sheet sheet,
    ReportModel report,
    List<MenuItem> menuItems,
  ) {
    int rowIndex = 0;

    // Title
    String titleText;
    switch (report.type) {
      case ReportType.weekly:
        titleText =
            'Báo cáo doanh thu Tuần ${_getWeekNumber(report.startDate)}/${report.startDate.year}';
        break;
      case ReportType.monthly:
        titleText =
            'Báo cáo doanh thu ${report.startDate.month}/${report.startDate.year}';
        break;
      case ReportType.yearly:
        titleText = 'Báo cáo doanh thu Năm ${report.startDate.year}';
        break;
    }

    // Title row
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
    );
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    titleCell.value = titleText;
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );
    rowIndex += 2;

    // Date range
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateRangeCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    dateRangeCell.value =
        'Từ ngày: ${dateFormat.format(report.startDate)} - Đến ngày: ${dateFormat.format(report.endDate)}';
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
    );
    rowIndex += 2;

    // Summary section
    final summaryTitleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    summaryTitleCell.value = 'Tổng quan';
    summaryTitleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
    rowIndex += 1;

    // Summary data
    final avgOrderValue = report.totalOrders > 0
        ? report.totalRevenue / report.totalOrders
        : 0.0;

    _addSummaryRow(
      sheet,
      rowIndex,
      'Tổng doanh thu',
      report.totalRevenue.toVnd(),
    );
    rowIndex += 1;
    _addSummaryRow(sheet, rowIndex, 'Tổng đơn hàng', '${report.totalOrders}');
    rowIndex += 1;
    _addSummaryRow(
      sheet,
      rowIndex,
      'Giá trị đơn trung bình',
      avgOrderValue.toVnd(),
    );
    rowIndex += 2;

    // Top Selling Items section
    if (report.itemSales.isNotEmpty) {
      final itemsTitleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      itemsTitleCell.value = 'Top món ăn bán chạy';
      itemsTitleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
      rowIndex += 1;

      // Table header
      final headers = ['STT', 'Tên món', 'Số lượng', 'Đơn giá', 'Doanh thu'];
      for (int i = 0; i < headers.length; i++) {
        final headerCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
        );
        headerCell.value = headers[i];
        headerCell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }
      rowIndex += 1;

      // Sort items by quantity sold (descending) and take top 10
      final sortedEntries = report.itemSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topItems = sortedEntries.take(10).toList();

      // Table data rows
      for (int i = 0; i < topItems.length; i++) {
        final entry = topItems[i];
        final menuItem = menuItems.firstWhere(
          (item) => item.id.toString() == entry.key,
          orElse: () => MenuItem(
            id: 0,
            name: 'Không xác định',
            price: 0,
            category: MenuCategory.food,
          ),
        );
        final revenue = report.itemRevenue[entry.key] ?? 0.0;

        // STT
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 0,
                    rowIndex: rowIndex,
                  ),
                )
                .value =
            i + 1;
        // Tên món
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = menuItem
            .name;
        // Số lượng
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = entry
            .value;
        // Đơn giá
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = menuItem
            .price;
        // Doanh thu
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 4,
                    rowIndex: rowIndex,
                  ),
                )
                .value =
            revenue;

        rowIndex += 1;
      }
    } else {
      final noDataCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      noDataCell.value = 'Không có dữ liệu bán hàng';
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );
    }

    // Auto-size columns
    sheet.setColumnWidth(0, 8); // STT
    sheet.setColumnWidth(1, 30); // Tên món
    sheet.setColumnWidth(2, 12); // Số lượng
    sheet.setColumnWidth(3, 15); // Đơn giá
    sheet.setColumnWidth(4, 15); // Doanh thu
  }

  /// Adds a summary row
  void _addSummaryRow(Sheet sheet, int rowIndex, String label, String value) {
    final labelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    labelCell.value = label;
    labelCell.cellStyle = CellStyle(bold: true);

    final valueCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
    );
    valueCell.value = value;
  }

  /// Saves the Excel file to device storage
  Future<File> _saveExcelFile(Excel excel, ReportModel report) async {
    // Get application documents directory
    final directory = await getApplicationDocumentsDirectory();

    // Create reports subdirectory if it doesn't exist
    final reportsDir = Directory('${directory.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    // Generate unique filename to avoid overwriting previous exports
    final baseFilename = _buildBaseFilename(report);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final preferredFilename = '${baseFilename}_$timestamp.xlsx';
    final uniquePath = await _buildUniqueFilePath(reportsDir, preferredFilename);
    final file = File(uniquePath);
    final excelBytes = excel.save();
    if (excelBytes == null) {
      throw const ExcelExportException('Không thể tạo dữ liệu tệp Excel.');
    }
    await file.writeAsBytes(excelBytes);

    return file;
  }

  Future<String> _buildUniqueFilePath(
    Directory directory,
    String preferredFilename,
  ) async {
    final extIndex = preferredFilename.lastIndexOf('.');
    final hasExtension = extIndex > 0;
    final namePart = hasExtension
        ? preferredFilename.substring(0, extIndex)
        : preferredFilename;
    final extPart = hasExtension ? preferredFilename.substring(extIndex) : '';

    var candidate = '${directory.path}/$preferredFilename';
    var suffix = 1;
    while (await File(candidate).exists()) {
      candidate = '${directory.path}/${namePart}_$suffix$extPart';
      suffix++;
    }
    return candidate;
  }

  /// Helper method to get week number
  int _getWeekNumber(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final daysSinceFirstJan = date.difference(firstJan).inDays;
    return ((daysSinceFirstJan + firstJan.weekday) / 7).ceil();
  }
}
