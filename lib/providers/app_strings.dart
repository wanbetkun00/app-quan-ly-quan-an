import '../models/enums.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'language_provider.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  // App
  String get appTitle =>
      language == AppLanguage.en ? 'TKA Restaurant' : 'Quản lý quán ăn TKA';

  // Bottom navigation
  String get navWaiter => language == AppLanguage.en ? 'Waiter' : 'Phục vụ';
  String get navKitchen =>
      language == AppLanguage.en ? 'Kitchen KDS' : 'Màn hình bếp';
  String get navManager => language == AppLanguage.en ? 'Manager' : 'Quản lý';

  // Screens titles
  String get waiterTitle =>
      language == AppLanguage.en ? 'Table Map' : 'Sơ đồ bàn';

  String get kitchenTitle =>
      language == AppLanguage.en ? 'Kitchen Display System' : 'Màn hình bếp';

  String get managerTitle =>
      language == AppLanguage.en ? 'Manager Admin' : 'Quản lý nhà hàng';

  // Waiter legends
  String get legendFree => language == AppLanguage.en ? 'Free' : 'Trống';
  String get legendBusy => language == AppLanguage.en ? 'Busy' : 'Đang dùng';
  String get legendPay => language == AppLanguage.en ? 'Pay' : 'Thanh toán';

  // Filter buttons
  String get filterAll => language == AppLanguage.en ? 'All' : 'Tất cả';
  String get filterFree => language == AppLanguage.en ? 'Free' : 'Trống';
  String get filterBusy => language == AppLanguage.en ? 'In Use' : 'Đang dùng';
  String get filterPaymentPending =>
      language == AppLanguage.en ? 'Payment Pending' : 'Chờ thanh toán';

  // Table status
  String get tableStatusAvailable =>
      language == AppLanguage.en ? 'Available' : 'Trống';
  String get tableStatusOccupied =>
      language == AppLanguage.en ? 'In Use' : 'Đang dùng';
  String get tableStatusPaymentPending =>
      language == AppLanguage.en ? 'Payment Pending' : 'Chờ thanh toán';

  // Order status
  String get orderStatusTitle =>
      language == AppLanguage.en ? 'Order Status' : 'Trạng thái đơn hàng';
  String get orderStatusPending =>
      language == AppLanguage.en ? 'Pending' : 'Chờ xử lý';
  String get orderStatusCooking =>
      language == AppLanguage.en ? 'Cooking' : 'Đang nấu';
  String get orderStatusReady =>
      language == AppLanguage.en ? 'Ready' : 'Sẵn sàng';
  String get orderStatusCompleted =>
      language == AppLanguage.en ? 'Completed' : 'Hoàn thành';

  // Common actions
  String get logout => language == AppLanguage.en ? 'Logout' : 'Đăng xuất';
  String get refresh => language == AppLanguage.en ? 'Refresh' : 'Làm mới';
  String get tableStatusLabel =>
      language == AppLanguage.en ? 'Status' : 'Trạng thái';

  // Table status (uppercase for display)
  String get tableStatusAvailableUpper =>
      language == AppLanguage.en ? 'AVAILABLE' : 'TRỐNG';
  String get tableStatusOccupiedUpper =>
      language == AppLanguage.en ? 'IN USE' : 'ĐANG DÙNG';
  String get tableStatusPaymentPendingUpper =>
      language == AppLanguage.en ? 'PAYMENT PENDING' : 'CHỜ THANH TOÁN';

  // Order status (for waiter screen)
  String get orderStatusPendingWait =>
      language == AppLanguage.en ? 'Waiting to cook' : 'Chờ nấu';
  String get orderStatusCookingWait =>
      language == AppLanguage.en ? 'Cooking' : 'Đang nấu';
  String get orderStatusReadyWait =>
      language == AppLanguage.en ? 'Ready' : 'Sẵn sàng';
  String get orderStatusCompletedWait =>
      language == AppLanguage.en ? 'Completed' : 'Hoàn thành';

  // Order status (uppercase for display)
  String get orderStatusPendingUpper =>
      language == AppLanguage.en ? 'PENDING' : 'CHỜ XỬ LÝ';
  String get orderStatusCookingUpper =>
      language == AppLanguage.en ? 'COOKING' : 'ĐANG NẤU';
  String get orderStatusReadyUpper =>
      language == AppLanguage.en ? 'READY' : 'SẴN SÀNG';
  String get orderStatusCompletedUpper =>
      language == AppLanguage.en ? 'COMPLETED' : 'HOÀN THÀNH';

  // Empty states
  String get noTablesAvailable =>
      language == AppLanguage.en ? 'No tables available' : 'Chưa có bàn nào';
  String get noOrdersToDisplay => language == AppLanguage.en
      ? 'No orders to display'
      : 'Không có đơn hàng nào để hiển thị';

  // Ordering sheet
  String orderingForTable(int id) => language == AppLanguage.en
      ? 'Ordering for Table $id'
      : 'Gọi món cho bàn $id';

  String get tabFood => language == AppLanguage.en ? 'FOOD' : 'MÓN ĂN';
  String get tabDrinks => language == AppLanguage.en ? 'DRINKS' : 'THỨC UỐNG';

  String get totalLabel => language == AppLanguage.en ? 'Total' : 'Tổng tiền';

  String get sendToKitchenButton =>
      language == AppLanguage.en ? 'SEND TO KITCHEN' : 'GỬI XUỐNG BẾP';

  String get orderSentSnack => language == AppLanguage.en
      ? 'Order sent to Kitchen!'
      : 'Đã gửi order xuống bếp!';

  // Kitchen screen
  String get noActiveOrders => language == AppLanguage.en
      ? 'No Active Orders'
      : 'Không có đơn hàng đang xử lý';

  String get kdsStartCooking =>
      language == AppLanguage.en ? 'START COOKING' : 'BẮT ĐẦU NẤU';
  String get kdsReadyToServe =>
      language == AppLanguage.en ? 'READY TO SERVE' : 'SẴN SÀNG PHỤC VỤ';
  String get kdsCompleteOrder =>
      language == AppLanguage.en ? 'COMPLETE ORDER' : 'HOÀN TẤT ĐƠN';

  // Manager screen
  String get mgrTabDashboard =>
      language == AppLanguage.en ? 'Dashboard' : 'Tổng quan';
  String get mgrTabMenu =>
      language == AppLanguage.en ? 'Menu Mgmt' : 'Quản lý món ăn';
  String get mgrTabTableManagement =>
      language == AppLanguage.en ? 'Table Management' : 'Quản lý bàn';
  String get mgrTabReports =>
      language == AppLanguage.en ? 'Reports' : 'Báo cáo';
  String get mgrTabShifts => language == AppLanguage.en ? 'Shifts' : 'Ca làm';
  String get mgrTabStaff => language == AppLanguage.en ? 'Staff' : 'Nhân viên';

  String get mgrTodayOverview =>
      language == AppLanguage.en ? "Today's Overview" : 'Tổng quan hôm nay';

  String get mgrDailyRevenue =>
      language == AppLanguage.en ? 'Daily Revenue' : 'Doanh thu hôm nay';

  String get mgrActiveOrders =>
      language == AppLanguage.en ? 'Active Orders' : 'Đơn hàng đang xử lý';

  String get mgrBestSellingDemo =>
      language == AppLanguage.en ? 'Best Selling Items' : 'Món bán chạy';

  String soldUnits(int n) =>
      language == AppLanguage.en ? '$n sold' : 'Đã bán $n';
  String get soldLabel => language == AppLanguage.en ? 'sold' : 'đã bán';

  String get mgrAddNewDish =>
      language == AppLanguage.en ? 'Add New Dish' : 'Thêm món mới';

  String get mgrStaffComingSoon => language == AppLanguage.en
      ? 'Staff Management Module'
      : 'Chức năng quản lý nhân viên';

  // Manager dashboard stats
  String get mgrTotalTables =>
      language == AppLanguage.en ? 'Total Tables' : 'Tổng số bàn';
  String get mgrAvailableTables =>
      language == AppLanguage.en ? 'Available Tables' : 'Bàn trống';
  String get mgrTotalMenuItems =>
      language == AppLanguage.en ? 'Total Items' : 'Tổng số món';
  String get mgrFoodDrinks =>
      language == AppLanguage.en ? 'Food / Drinks' : 'Món ăn / Thức uống';
  String get mgrNoDataYet =>
      language == AppLanguage.en ? 'No data yet' : 'Chưa có dữ liệu';
  String get mgrNoCompletedOrders => language == AppLanguage.en
      ? 'No completed orders yet'
      : 'Chưa có đơn hàng hoàn thành';

  // Table management
  String get addNewTable =>
      language == AppLanguage.en ? 'Add New Table' : 'Thêm bàn mới';
  String get editTableInfo => language == AppLanguage.en
      ? 'Edit Table Information'
      : 'Sửa thông tin bàn';
  String get tableNumberLabel =>
      language == AppLanguage.en ? 'Table Number (ID)' : 'Số bàn (ID)';
  String get tableNumberHelper => language == AppLanguage.en
      ? 'Table number must be a positive integer'
      : 'Số bàn phải là số nguyên dương';
  String get tableNumberInvalid => language == AppLanguage.en
      ? 'Invalid table number'
      : 'Số bàn không hợp lệ';
  String get tableNumberRequired => language == AppLanguage.en
      ? 'Please enter table number'
      : 'Vui lòng nhập số bàn';
  String get tableNameLabel =>
      language == AppLanguage.en ? 'Table Name' : 'Tên bàn';
  String get tableNameExample => language == AppLanguage.en
      ? 'Example: Table 1, T1, Table 1'
      : 'Ví dụ: Bàn 1, T1, Table 1';
  String get tableNameRequired => language == AppLanguage.en
      ? 'Please enter table name'
      : 'Vui lòng nhập tên bàn';
  String get addTableButton =>
      language == AppLanguage.en ? 'Add Table' : 'Thêm bàn';
  String get updateButton => language == AppLanguage.en ? 'Update' : 'Cập nhật';
  String get cancelButton => language == AppLanguage.en ? 'Cancel' : 'Hủy';
  String get validIdRequired => language == AppLanguage.en
      ? 'Please enter a valid ID'
      : 'Vui lòng nhập ID hợp lệ';

  // Reports screen
  String get reportsTitle => language == AppLanguage.en ? 'Reports' : 'Báo cáo';
  String get reportByWeek =>
      language == AppLanguage.en ? 'By Week' : 'Theo tuần';
  String get reportByMonth =>
      language == AppLanguage.en ? 'By Month' : 'Theo tháng';
  String get reportByYear =>
      language == AppLanguage.en ? 'By Year' : 'Theo năm';
  String get selectMonthYear =>
      language == AppLanguage.en ? 'Select Month/Year' : 'Chọn tháng/năm';
  String get selectYear =>
      language == AppLanguage.en ? 'Select Year' : 'Chọn năm';
  String get yearLabel => language == AppLanguage.en ? 'Year:' : 'Năm:';
  String get monthLabel => language == AppLanguage.en ? 'Month:' : 'Tháng:';
  String get selectButton => language == AppLanguage.en ? 'Select' : 'Chọn';
  String get noReportData =>
      language == AppLanguage.en ? 'No report data' : 'Chưa có dữ liệu báo cáo';
  String get loadLatestReport => language == AppLanguage.en
      ? 'Load Latest Report'
      : 'Tải báo cáo mới nhất';
  String get selectDifferentDate =>
      language == AppLanguage.en ? 'Select Different Date' : 'Chọn ngày khác';
  String reportForPeriod(String period) =>
      language == AppLanguage.en ? 'Report $period' : 'Báo cáo $period';
  String get totalRevenue =>
      language == AppLanguage.en ? 'Total Revenue' : 'Tổng doanh thu';
  String get totalOrders =>
      language == AppLanguage.en ? 'Total Orders' : 'Tổng đơn hàng';
  String get averageOrder =>
      language == AppLanguage.en ? 'Average Order' : 'Đơn hàng trung bình';
  String get itemsSold =>
      language == AppLanguage.en ? 'Items Sold' : 'Số món đã bán';
  String get noSalesData =>
      language == AppLanguage.en ? 'No sales data' : 'Chưa có dữ liệu bán hàng';
  String get units => language == AppLanguage.en ? 'units' : 'đơn vị';
  String get saveReport =>
      language == AppLanguage.en ? 'Save This Report' : 'Lưu báo cáo này';
  String get reportSavedSuccess => language == AppLanguage.en
      ? 'Report saved successfully!'
      : 'Đã lưu báo cáo thành công!';
  String errorLoadingReport(String error) => language == AppLanguage.en
      ? 'Error loading report: $error'
      : 'Lỗi khi tải báo cáo: $error';
  String errorGeneratingReport(String error) => language == AppLanguage.en
      ? 'Error generating report: $error'
      : 'Lỗi khi tạo báo cáo: $error';
  String errorSavingReport(String error) => language == AppLanguage.en
      ? 'Error saving report: $error'
      : 'Lỗi khi lưu báo cáo: $error';

  // Shift management screen
  String get shiftManagementTitle =>
      language == AppLanguage.en ? 'Shift Management' : 'Quản lý ca làm';
  String get addNewShift =>
      language == AppLanguage.en ? 'Add New Shift' : 'Thêm ca làm mới';
  String get filterByEmployee => language == AppLanguage.en
      ? 'Filter by employee:'
      : 'Lọc theo nhân viên:';
  String get allEmployees =>
      language == AppLanguage.en ? 'All Employees' : 'Tất cả nhân viên';
  String get noShiftsThisWeek => language == AppLanguage.en
      ? 'No shifts this week'
      : 'Không có ca làm trong tuần này';
  String get today => language == AppLanguage.en ? 'Today' : 'Hôm nay';
  String get shifts => language == AppLanguage.en ? 'shifts' : 'ca';
  String get shiftScheduled =>
      language == AppLanguage.en ? 'Scheduled' : 'Đã lên lịch';
  String get shiftCompleted =>
      language == AppLanguage.en ? 'Completed' : 'Đã hoàn thành';
  String get shiftCancelled =>
      language == AppLanguage.en ? 'Cancelled' : 'Đã hủy';
  String get editButton => language == AppLanguage.en ? 'Edit' : 'Sửa';
  String get deleteButton => language == AppLanguage.en ? 'Delete' : 'Xóa';
  String get confirmDelete =>
      language == AppLanguage.en ? 'Confirm Delete' : 'Xác nhận xóa';
  String confirmDeleteShift(String employeeName) => language == AppLanguage.en
      ? 'Are you sure you want to delete shift for $employeeName?'
      : 'Bạn có chắc muốn xóa ca làm của $employeeName?';
  String shiftAddedFor(String employeeName) => language == AppLanguage.en
      ? 'Shift added for $employeeName'
      : 'Đã thêm ca làm cho $employeeName';
  String get errorAddingShift =>
      language == AppLanguage.en ? 'Error adding shift' : 'Lỗi khi thêm ca làm';
  String get shiftUpdated =>
      language == AppLanguage.en ? 'Shift updated' : 'Đã cập nhật ca làm';
  String get errorUpdatingShift => language == AppLanguage.en
      ? 'Error updating shift'
      : 'Lỗi khi cập nhật ca làm';
  String get shiftDeleted =>
      language == AppLanguage.en ? 'Shift deleted' : 'Đã xóa ca làm';
  String get errorDeletingShift => language == AppLanguage.en
      ? 'Error deleting shift'
      : 'Lỗi khi xóa ca làm';
  String get errorLoading => language == AppLanguage.en ? 'Error:' : 'Lỗi:';
  String get editShift =>
      language == AppLanguage.en ? 'Edit Shift' : 'Sửa ca làm';
  String get employeeLabel =>
      language == AppLanguage.en ? 'Employee' : 'Nhân viên';
  String get selectEmployeeRequired => language == AppLanguage.en
      ? 'Please select an employee'
      : 'Vui lòng chọn nhân viên';
  String get workDayLabel =>
      language == AppLanguage.en ? 'Work Day' : 'Ngày làm việc';
  String get startTimeLabel =>
      language == AppLanguage.en ? 'Start Time' : 'Giờ bắt đầu';
  String get endTimeLabel =>
      language == AppLanguage.en ? 'End Time' : 'Giờ kết thúc';
  String get notesLabel =>
      language == AppLanguage.en ? 'Notes (optional)' : 'Ghi chú (tùy chọn)';
  String get saveButton => language == AppLanguage.en ? 'Save' : 'Lưu';
  String get shiftOverlapWarning => language == AppLanguage.en
      ? 'Shift Overlap Warning'
      : 'Cảnh báo trùng ca làm';
  String get employeeHasOverlappingShift => language == AppLanguage.en
      ? 'This employee already has a shift overlapping with the time you selected:'
      : 'Nhân viên này đã có ca làm trùng với thời gian bạn chọn:';
  String get continueAddingShift => language == AppLanguage.en
      ? 'Do you want to continue adding this shift?'
      : 'Bạn có muốn tiếp tục thêm ca làm này không?';
  String get addAnyway =>
      language == AppLanguage.en ? 'Add Anyway' : 'Vẫn thêm';

  // My Shifts screen (Waiter)
  String get myShiftsTitle =>
      language == AppLanguage.en ? 'My Shifts' : 'Ca làm của tôi';
  String get previousWeek =>
      language == AppLanguage.en ? 'Previous Week' : 'Tuần trước';
  String get thisWeek => language == AppLanguage.en ? 'This Week' : 'Tuần này';
  String get nextWeek => language == AppLanguage.en ? 'Next Week' : 'Tuần sau';
  String weekLabel(int weekNumber, int year) => language == AppLanguage.en
      ? 'Week $weekNumber/$year'
      : 'Tuần $weekNumber/$year';
  String get noShifts =>
      language == AppLanguage.en ? 'No shifts' : 'Không có ca';
  String get hours => language == AppLanguage.en ? 'hours' : 'giờ';

  // Weekday abbreviations
  String get weekdaySun => language == AppLanguage.en ? 'Sun' : 'CN';
  String get weekdayMon => language == AppLanguage.en ? 'Mon' : 'T2';
  String get weekdayTue => language == AppLanguage.en ? 'Tue' : 'T3';
  String get weekdayWed => language == AppLanguage.en ? 'Wed' : 'T4';
  String get weekdayThu => language == AppLanguage.en ? 'Thu' : 'T5';
  String get weekdayFri => language == AppLanguage.en ? 'Fri' : 'T6';
  String get weekdaySat => language == AppLanguage.en ? 'Sat' : 'T7';

  String getWeekdayAbbr(int weekday) {
    // weekday: 1=Monday, 7=Sunday
    // Convert to 0=Sunday, 1=Monday, ..., 6=Saturday
    final index = weekday % 7;
    switch (index) {
      case 0:
        return weekdaySun;
      case 1:
        return weekdayMon;
      case 2:
        return weekdayTue;
      case 3:
        return weekdayWed;
      case 4:
        return weekdayThu;
      case 5:
        return weekdayFri;
      case 6:
        return weekdaySat;
      default:
        return weekdaySun;
    }
  }
}

extension AppStringsContext on BuildContext {
  AppStrings get strings {
    final lang = Provider.of<LanguageProvider>(this).language;
    return AppStrings(lang);
  }
}
