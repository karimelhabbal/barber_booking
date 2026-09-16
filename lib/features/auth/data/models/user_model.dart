import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    super.name,
    super.phone,
    super.role,
    super.barberShopId,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('User document ${document.id} does not exist.');
    }

    return UserModel(
      id: document.id,
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      role: _roleFromString(data['role'] as String?),
      barberShopId: data['barberShopId'] as String?,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: _roleFromString(json['role'] as String?),
      barberShopId: json['barberShopId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': _roleToString(role),
      'barberShopId': barberShopId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': _roleToString(role),
      'barberShopId': barberShopId,
    };
  }

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'barber':
        return UserRole.barber;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'owner';
      case UserRole.barber:
        return 'barber';
      case UserRole.customer:
        return 'customer';
    }
  }
}
