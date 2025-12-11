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
  String get waiterTitle => language == AppLanguage.en
      ? 'Table Map (Front-of-House)'
      : 'Sơ đồ bàn (Khu phục vụ)';

  String get kitchenTitle => language == AppLanguage.en
      ? 'Kitchen Display System (KDS)'
      : 'Màn hình bếp (KDS)';

  String get managerTitle =>
      language == AppLanguage.en ? 'Manager Admin' : 'Quản lý nhà hàng';

  // Waiter legends
  String get legendFree => language == AppLanguage.en ? 'Free' : 'Trống';
  String get legendBusy => language == AppLanguage.en ? 'Busy' : 'Đang dùng';
  String get legendPay => language == AppLanguage.en ? 'Pay' : 'Thanh toán';

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
  String get mgrTabStaff => language == AppLanguage.en ? 'Staff' : 'Nhân viên';

  String get mgrTodayOverview =>
      language == AppLanguage.en ? "Today's Overview" : 'Tổng quan hôm nay';

  String get mgrDailyRevenue =>
      language == AppLanguage.en ? 'Daily Revenue' : 'Doanh thu hôm nay';

  String get mgrActiveOrders =>
      language == AppLanguage.en ? 'Active Orders' : 'Đơn hàng đang xử lý';

  String get mgrBestSellingDemo => language == AppLanguage.en
      ? 'Best Selling Items (Demo)'
      : 'Món bán chạy (demo)';

  String soldUnits(int n) =>
      language == AppLanguage.en ? '$n sold' : 'Đã bán $n';

  String get mgrAddNewDish =>
      language == AppLanguage.en ? 'Add New Dish' : 'Thêm món mới';

  String get mgrStaffComingSoon => language == AppLanguage.en
      ? 'Staff Management Module\n(Coming Soon)'
      : 'Chức năng quản lý nhân viên\n(Soon sẽ có)';
}

extension AppStringsContext on BuildContext {
  AppStrings get strings {
    final lang = Provider.of<LanguageProvider>(this).language;
    return AppStrings(lang);
  }
}

