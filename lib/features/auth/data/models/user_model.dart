import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.id, super.name, super.phone, super.role, super.barberShopId});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String?,
    phone: json['phone'] as String?,
    role: _roleFromString(json['role'] as String?),
    barberShopId: (json['barber_shop_id'] ?? json['barberShopId']) as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'role': _roleToString(role),
    'barber_shop_id': barberShopId,
  };

  static UserRole _roleFromString(String? value) => switch (value) {
    'owner' => UserRole.owner, 'barber' => UserRole.barber, _ => UserRole.customer,
  };
  static String _roleToString(UserRole role) => switch (role) {
    UserRole.owner => 'owner', UserRole.barber => 'barber', UserRole.customer => 'customer',
  };
}
