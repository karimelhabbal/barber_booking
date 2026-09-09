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
