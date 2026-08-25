import 'package:equatable/equatable.dart';

enum UserRole { owner, barber, customer }

class UserModel extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final UserRole role;
  final String? barberShopId;

  const UserModel({
    required this.id,
    this.name,
    this.phone,
    this.role = UserRole.customer,
    this.barberShopId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?) ?? 'customer';
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == roleStr,
        orElse: () => UserRole.customer,
      ),
      barberShopId: json['barberShopId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role.toString().split('.').last,
        'barberShopId': barberShopId,
      };

  @override
  List<Object?> get props => [id, name, phone, role, barberShopId];
}
