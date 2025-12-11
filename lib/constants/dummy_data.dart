import '../models/models.dart';

List<TableModel> dummyTables = List.generate(
  12,
  (index) => TableModel(id: index + 1, name: 'T ${index + 1}'),
);

List<MenuItem> dummyMenu = [
  MenuItem(
    id: 1,
    name: 'Phở bò đặc biệt',
    price: 45000,
    category: MenuCategory.food,
  ),
  MenuItem(
    id: 2,
    name: 'Bún chả Hà Nội',
    price: 40000,
    category: MenuCategory.food,
  ),
  MenuItem(
    id: 3,
    name: 'Cơm tấm sườn bì chả',
    price: 38000,
    category: MenuCategory.food,
  ),
  MenuItem(
    id: 4,
    name: 'Gỏi cuốn tôm thịt',
    price: 30000,
    category: MenuCategory.food,
  ),
  MenuItem(
    id: 10,
    name: 'Coca-Cola',
    price: 15000,
    category: MenuCategory.drink,
  ),
  MenuItem(
    id: 11,
    name: 'Nước cam ép',
    price: 20000,
    category: MenuCategory.drink,
  ),
  MenuItem(
    id: 12,
    name: 'Cà phê sữa đá',
    price: 18000,
    category: MenuCategory.drink,
  ),
];

