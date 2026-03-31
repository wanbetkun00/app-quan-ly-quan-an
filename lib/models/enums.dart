enum TableStatus { available, occupied, paymentPending }

enum OrderStatus { pending, cooking, readyToServe, completed }

enum MenuCategory { food, drink }

enum AppLanguage { en, vi }

enum UserRole { manager, cashier, waiter }

extension UserRoleX on UserRole {
  String get displayNameVi {
    switch (this) {
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.cashier:
        return 'Thu ngân';
      case UserRole.waiter:
        return 'Phục vụ';
    }
  }
}

enum ShiftStatus { scheduled, completed, cancelled }

