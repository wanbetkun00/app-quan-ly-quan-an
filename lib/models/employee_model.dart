import 'enums.dart';

class EmployeeModel {
  final String id;
  final String username;
  final String name;
  final String password; // Trong thực tế nên hash password
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeModel({
    required this.id,
    required this.username,
    required this.name,
    required this.password,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'password': password, // Trong thực tế nên hash
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory EmployeeModel.fromFirestore(String docId, Map<String, dynamic> data) {
    // Luôn sử dụng docId làm id chính (document ID thực tế trong Firestore)
    // Field 'id' trong data chỉ là metadata, không phải document ID thực tế
    final employeeId = docId;

    return EmployeeModel(
      id: employeeId,
      username: data['username'] as String? ?? '',
      name: data['name'] as String? ?? '',
      password: data['password'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.staff,
      ),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is String
                ? DateTime.parse(data['createdAt'] as String)
                : (data['createdAt'] as DateTime?))
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is String
                ? DateTime.parse(data['updatedAt'] as String)
                : (data['updatedAt'] as DateTime?))
          : null,
    );
  }

  // Create a copy with updated fields
  EmployeeModel copyWith({
    String? id,
    String? username,
    String? name,
    String? password,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
