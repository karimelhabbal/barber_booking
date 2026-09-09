import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/service.dart';

class ServiceModel extends Service {
  const ServiceModel({
    required super.id,
    required super.barberShopId,
    required super.name,
    super.description,
    required super.durationMinutes,
    required super.price,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ServiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Service document ${document.id} does not exist.');
    }

    return ServiceModel(
      id: document.id,
      barberShopId: data['barberShopId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'barberShopId': barberShopId,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
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
}
