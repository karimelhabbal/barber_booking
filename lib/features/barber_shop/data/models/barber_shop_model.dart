import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/barber_shop.dart';

class BarberShopModel extends BarberShop {
  const BarberShopModel({
    required super.id,
    required super.name,
    required super.ownerId,
    super.phone,
    super.address,
    super.description,
    super.imageUrl,
    required super.timezone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BarberShopModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Barber shop document ${document.id} does not exist.');
    }

    return BarberShopModel(
      id: document.id,
      name: data['name'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      timezone: data['timezone'] as String? ?? 'Africa/Cairo',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'phone': phone,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'timezone': timezone,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _timestampToDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    throw StateError('Expected Firestore Timestamp but received $value.');
  }

  factory BarberShopModel.fromEntity(BarberShop shop) {
    return BarberShopModel(
      id: shop.id,
      name: shop.name,
      ownerId: shop.ownerId,
      phone: shop.phone,
      address: shop.address,
      description: shop.description,
      imageUrl: shop.imageUrl,
      timezone: shop.timezone,
      isActive: shop.isActive,
      createdAt: shop.createdAt,
      updatedAt: shop.updatedAt,
    );
  }
}
