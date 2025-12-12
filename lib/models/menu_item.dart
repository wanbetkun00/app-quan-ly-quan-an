import 'enums.dart';

class MenuItem {
  final int id;
  final String name;
  final double price;
  final MenuCategory category;
  final String? imageUrl; // URL hoặc đường dẫn file ảnh

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
  });
}

