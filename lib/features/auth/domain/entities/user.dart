import 'package:equatable/equatable.dart';

enum UserRole { owner, barber, customer }

class User extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final UserRole role;
  final String? barberShopId;

  const User({
    required this.id,
    this.name,
    this.phone,
    this.role = UserRole.customer,
    this.barberShopId,
  });

  @override
  List<Object?> get props => [id, name, phone, role, barberShopId];
}
