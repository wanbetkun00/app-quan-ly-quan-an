import 'menu_item.dart';

class OrderItem {
  final MenuItem menuItem;
  int quantity;

  OrderItem({required this.menuItem, this.quantity = 1});
}

