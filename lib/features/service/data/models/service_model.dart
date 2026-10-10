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

  factory ServiceModel.fromJson(Map<String, dynamic> data) {
    return ServiceModel(
      id: data['id'] as String,
      barberShopId: data['barber_shop_id'] as String? ?? data['barberShopId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? (data['durationMinutes'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      isActive: data['is_active'] as bool? ?? data['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barber_shop_id': barberShopId,
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ServiceModel.fromEntity(Service service) {
    return ServiceModel(
      id: service.id,
      barberShopId: service.barberShopId,
      name: service.name,
      description: service.description,
      durationMinutes: service.durationMinutes,
      price: service.price,
      isActive: service.isActive,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
    );
  }

}
