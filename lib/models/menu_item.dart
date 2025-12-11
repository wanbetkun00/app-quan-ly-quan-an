import 'enums.dart';

class MenuItem {
  final int id;
  final String name;
  final double price;
  final MenuCategory category;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });
}

