enum TableStatus { available, occupied, paymentPending }

enum OrderStatus { pending, cooking, readyToServe, completed }

enum MenuCategory { food, drink }

enum AppLanguage { en, vi }

enum UserRole { staff, cashier, manager }

extension UserRoleX on UserRole {
  String get displayNameVi {
    switch (this) {
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.cashier:
        return 'Thu ngân';
      case UserRole.manager:
        return 'Quản lý';
    }
  }
}

enum ShiftStatus { scheduled, completed, cancelled }

