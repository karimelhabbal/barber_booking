import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/barber.dart';

class BarberModel extends Barber {
  const BarberModel({
    required super.id,
    required super.userId,
    required super.barberShopId,
    required super.name,
    super.phone,
    super.imageUrl,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BarberModel.fromSupabase(Map<String, dynamic> row) {
    return BarberModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      barberShopId: row['barber_shop_id'] as String,
      name: row['name'] as String? ?? '',
      phone: row['phone'] as String?,
      imageUrl: row['image_url'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'user_id': userId,
    'barber_shop_id': barberShopId,
    'name': name,
    'phone': phone,
    'image_url': imageUrl,
    'is_active': isActive,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory BarberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Barber document ${document.id} does not exist.');
    }

    return BarberModel(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      barberShopId: data['barberShopId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      imageUrl: data['imageUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'barberShopId': barberShopId,
      'name': name,
      'phone': phone,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BarberModel.fromEntity(Barber barber) {
    return BarberModel(
      id: barber.id,
      userId: barber.userId,
      barberShopId: barber.barberShopId,
      name: barber.name,
      phone: barber.phone,
      imageUrl: barber.imageUrl,
      isActive: barber.isActive,
      createdAt: barber.createdAt,
      updatedAt: barber.updatedAt,
    );
  }

  static DateTime _timestampToDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    throw StateError('Expected Firestore Timestamp but received $value.');
  }
}
